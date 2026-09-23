# sing-box subscriptions — replacing the banned WireGuard exit

The self-hosted WireGuard endpoint (`snejugal.ru`) is no longer usable as a
general exit. The split-tunnel router keeps its shape — corp via the SOCKS
bridge, RU-inside direct, everything else through a tunnel — but the "everything
else" leg moves from `wg` to a friend's subscription.

Everything below was verified against **sing-box 1.14.1** (the version in the
pinned nixpkgs), not inferred from docs. Status: **implemented.** This file is
the "why"; `spec.md` next to it is the "what".

---

## 1. Decisions

| Question | Decision |
| --- | --- |
| Which subscription | **amenocturne only** |
| `wg` endpoint | **Kept**, for peers only — no longer `route.final` |
| Blanc subscription | **Out of scope** — stays in a separate client |
| Homelab | **Same shape as the mac** — subscription + `wg` for peers |
| Client on the Mac | **SFM (GUI) stays.** No move to CLI sing-box |
| OpenSpec change | Not opened; this doc plus `spec.md` are the record |

---

## 2. What the two subscriptions actually are

### amenocturne (`sub.amenocturne.space`) — the one we use

Remnawave panel. Default response is a base64 list of v2ray URIs, but it **also
serves a complete sing-box config at the `/singbox` path suffix**. Note that
`?client_type=singbox` does *not* work — only the path suffix does. The
`SFM/1.14.0` User-Agent triggers the same JSON on the base URL.

- 6 nodes: 1 × hysteria2, 5 × vless-REALITY
- **Byte-identical across fetches** (verified by sha256) — safe to pin
- Its own config is unusable wholesale: no corp/RU routing, and it uses the
  legacy pre-1.12 DNS schema (`address: "tls://1.1.1.1"`, `dns.fakeip`). Only
  its `outbounds` array is taken.

### Blanc (`withblancvpn.online`) — deferred

- Base64 URI list only. `?format=` is recognised but every value except `json`
  returns `{"message":"Format not supported"}`. No sing-box output at all.
- 50 × vless-REALITY, one UUID, all port 443.
- **Rotates `sni` and `sid` on every single fetch** (46/50 and 49/50 differed
  between two back-to-back fetches; host/port/pubkey stable).
  `profile-update-interval: 1` day. Cannot be pinned.

---

## 3. Why the design is what it is

**sing-box has no subscription support.** Confirmed against the v1.14.1 source
tree: no provider adapter or doc. The only `provider.go` files are the Clash-API
*serving* side and certificate providers. Nothing in the config fetches a URL of
proxies.

**SFM's Remote Profile is a sing-box config file, not a subscription parser**
(`docs/clients/general.md`). So:

- Ameno *could* be a Remote Profile directly — but that throws away the corp/RU
  routing, which is the entire point of this setup.
- Blanc could never be one.

**Config merging (`sing-box run -C <dir>`) would solve this cleanly** — arrays
concatenate, scalars from later files win, and cross-file tag references resolve
(a `selector` in one file can name a `urltest` defined in another; `check` passes
and it runs). One trap: **merge order is lexicographic by filename, not `-c`
argument order.**

But merging is CLI-only — SFM cannot do it. Since we are staying on SFM, the
subscription is instead **baked into the generated profile at activation time**.
This is viable precisely because ameno is byte-stable; it would not be for Blanc.

---

## 4. Target config shape

```
endpoints: wg                             (kept — the 10.6.6.0/24 peer rule needs it)
outbounds: direct
           <spliced from sops, as ONE opaque blob:
              6 ameno nodes
              urltest  "proxy-auto" -> the 6 node tags
              selector "proxy"      -> [ proxy-auto, wg, direct, <the 6 tags> ] >
route.rules:  sniff -> hijack-dns -> corp(socks) -> ru-rulesets(direct) -> private(direct)
route.final:  proxy                       (was: wg)
dns:          tunnel-dns detour -> proxy  (was: wg)
```

`lib/sing-box/corp.nix` needs no changes — it splices positionally ahead of the
first outbound-selecting rule, which still holds.

### Keeping the nodes out of the Nix store

The node list is a credential (account UUID, REALITY keys, and it exposes a
friend's servers), so it follows the same sops discipline as the WireGuard
identity. `sops.placeholder` is a string, but the nodes are a JSON *array* —
bridged by substituting after `toJSON`:

```nix
builtins.replaceStrings
  [ "\"@@PROXY_OUTBOUNDS@@\"" ]
  [ config.sops.placeholder."sing-box/proxy-outbounds" ]
  (builtins.toJSON cfg)
```

`"@@PROXY_OUTBOUNDS@@"` sits in the `outbounds` list as a marker; `toJSON` renders it
quoted, `replaceStrings` strips the quotes along with it, and sops expands the
placeholder to the bare array elements at activation. Verified to produce valid
JSON.

The secret value is that array with its **outer brackets stripped**.

### Why the groups live in the secret, not in nix

First cut named the node tags in nix so the `urltest` could list them. Two
problems, both real:

1. The tags (`ameno/reality-de1`, …) landed in the **world-readable Nix store**.
   No credentials, but it leaks the provider and the rough geography.
2. It forced a second, hand-maintained copy of the tag list in
   `modules/home/sing-box.nix` that only failed at *activation* when it drifted.

Moving the `urltest` and `selector` into the secret fixes both: the refresh
recipe emits them, and nix never names a node. Verified — the store template's
outbounds are exactly `["direct", <opaque blob>]`, and grepping it for
`amenocturne|ameno|reality|hysteria|vultr|nl2|de1` returns nothing.

The groups reference `wg` and `direct`, which are defined in nix. That is fine:
sing-box resolves tags across the whole config, not per-file.

---

## 5. Refresh procedure

Manual, via `just refresh-sing-box-subscription` — appropriate given the content is byte-stable.
No converter script is needed since ameno already speaks sing-box:

```bash
url="$(sops decrypt --extract '["sing-box"]["subscription-url"]' secrets.yaml)"
curl -fsS --max-time 30 -A 'SFM/1.14.0' "$url/singbox" \
  | jq -c '[ .outbounds[]
             | select(.type | IN("direct","block","dns","selector","urltest") | not)
             | .tag = "ameno/" + .tag ]'
```

Output goes into `secrets.yaml` under `sing-box/proxy-outbounds` (brackets
stripped), then re-activate and re-import the profile into SFM.

---

## 6. As built

| File | Change |
| --- | --- |
| `lib/sing-box/default.nix` | `proxyOutbounds` / `proxyOutboundTags` args; nodes + `proxy-auto` urltest + `proxy` selector; `final` and `tunnel-dns` detour follow `defaultOutbound`; `http_clients` fix; **`ruleSetDetourField` removed** |
| `modules/home/sing-box.nix` | `sing-box/proxy-outbounds` secret; `renderConfig` does the splice for both profiles |
| `justfile` | emits the urltest + selector alongside the nodes |
| `lib/sing-box/render.nix` | **new** — marker, secret name, the splice, and the dummy-secret render used by both build-time checks |
| `modules/nixos/sing-box.nix` | same shape as the mac: `settings = { }`, sops template into `/etc/sing-box/config.json` |
| `modules/nixos/server/default.nix` | drive-by: `services.journald.extraConfig` → `settings.Journal` (removed upstream; blocked homelab eval) |
| `lib/sing-box/corp.nix` | none, as predicted |
| `secrets.yaml` | `sing-box/subscription-url`, `sing-box/proxy-outbounds` |

### Both hosts, one path

The homelab runs the same shape as the mac. That forced a change of mechanism
there, because the two substitution systems differ:

* `sops.placeholder` (mac) is a string.
* NixOS `services.sing-box.settings` takes `{ _secret = path; }` leaves and runs
  them through `genJqSecretsReplacementSnippet`, which substitutes **string
  values**.

The subscription is an *array of objects*, which neither can express — so the
`{ _secret = ... }` path had to go. `services.sing-box.settings` is now `{ }`,
which flips the module's ExecStart from `RUNTIME_DIRECTORY` to
`CONFIGURATION_DIRECTORY`:

```nix
configDir = if cfg.settings != { } then "RUNTIME_DIRECTORY" else "CONFIGURATION_DIRECTORY";
ExecStart = "sing-box -D $STATE_DIRECTORY -C ${configDir} run";
```

So the homelab gets a sops-rendered `/etc/sing-box/config.json` (a symlink to
`/run/secrets/rendered/...`, owned by the `sing-box` user) and both hosts share
`lib/sing-box/render.nix`. Secrets still never reach the Nix store on either.

`proxyOutbounds` is a **required** argument. It briefly had a `null` default
that fell back to the old `wg`-as-`route.final` shape, kept for the homelab —
once the homelab moved too, nothing could reach that branch, so it went, along
with the `useProxy` / `defaultOutbound` plumbing. `route.final` and the tunnel
DNS detour now just say `proxy`.

There is no tag list in nix to keep in sync — see "Why the groups live in the
secret" above.

---

## 7. Startup deadlock: `direct-dns` must not be `type = "local"`

Found the hard way, after the first activation: the mac's profile came up but
resolved nothing, so every site failed. The config was valid and ran fine under
a `mixed` inbound — the deadlock only exists under an `auto_route` tun:

```
urltest probe -> needs www.gstatic.com
              -> route.default_domain_resolver = direct-dns (type "local" = system resolver)
              -> under the tun, that query is captured by the tun inbound
              -> hijack-dns -> dns.final = tunnel-dns -> detour "proxy"
              -> proxy -> proxy-auto (urltest), not ready yet
              => no DNS until the proxy is up, no proxy until DNS works
```

This was latent until the default outbound stopped being `wg`. A WireGuard
endpoint has no health probe, so `tunnel-dns`'s detour was always immediately
"ready"; a `urltest`-backed selector is not. `type = "local"` was fine on macOS
for exactly that reason, and stopped being fine the moment this change landed.

Fix: `direct-dns` talks to an upstream directly (`type = "udp"`, `1.1.1.1`, no
`detour`) on both hosts, so nothing sing-box needs for its own bootstrap depends
on the proxy being up. That is what the homelab already did, which is why the
homelab activated cleanly and the mac did not.

**Neither `sing-box check` nor a `mixed`-inbound run catches this.** It needs a
real tun. When changing DNS or the default outbound, test in SFM (mac) or as the
service (homelab), not just with a scratch config.

### 7b. `direct-dns` must be DoH, not UDP:53

The first fix for the deadlock made `direct-dns` a plain `type = "udp"` resolver
at 1.1.1.1. That is dead on the mac's network — measured, not assumed:

| probe | result |
| --- | --- |
| `dig @1.1.1.1` | timeout |
| `dig @8.8.8.8` | timeout |
| `dig @77.88.8.8` (Yandex) | timeout |
| DoH `https://1.1.1.1/dns-query` | HTTP 200 |

Plain DNS egress is filtered, which is routine on Russian ISPs. So `direct-dns`
is `type = "https"` — same address, port 443. Given as an IP, so it needs no
bootstrap resolution of its own. RU-inside resolution went from timing out to
answering in 9ms.

### 7c. `dns.strategy = "ipv4_only"` — why the browser broke but curl did not

The reported symptom was `curl ifconfig.me` working while Chrome could not load
google.com. Cause: **the subscription nodes have no IPv6 egress** — `v6.ifconfig.co`
through the proxy fails outright. Handing a client an AAAA the tunnel cannot
service is worse than having none: curl falls back to v4 quickly, browsers
follow happy-eyeballs into the dead v6 path and stall.

This is the same failure shape as the old WireGuard v6 black-hole, but total
rather than slow. The provider's own generated config sets `ipv4_only` for the
same reason.

`dns.strategy` is global — per-rule `strategy` is deprecated in 1.14, removed in
1.16. It costs v6 on the direct (RU) leg too, a real but small loss against a
hanging browser.

### 7d. QUIC and IPv6 must be rejected at the *route* level, not just in DNS

`dns.strategy = "ipv4_only"` (7c) was not enough — the browser still hung while
`curl` stayed fine. Cause, read straight out of the live Firefox profile
(`Profiles/2xm5jxz4.default/prefs.js`):

```
doh-rollout.self-enabled : true
doh-rollout.uri          : https://mozilla.cloudflare-dns.com/dns-query
doh-rollout.home-region  : "NL"      <- detected from the VPN exit
```

**Firefox resolves DNS itself over DoH.** It never asks sing-box, so no
`dns.*` setting can reach it: it gets AAAA records directly from Cloudflare,
tries IPv6 through nodes that have none, and stalls on happy-eyeballs. It also
honours `alpn=h3` from the HTTPS RR and opens QUIC on UDP:443, whose relay does
not work through vless nodes that carry no `packet_encoding`. The system `curl`
uses the OS resolver (which *does* go through sing-box) and has no HTTP/3 at
all — hence the split.

Fix: two `reject` rules at the end of `route.rules`, so a client that resolves
for itself still fails *fast* and falls back:

| rule | effect |
| --- | --- |
| `network=udp, port=443` | QUIC dies instantly, browser falls back to h2 |
| `ip_version=6` | v6 dies instantly, browser falls back to v4 |

Both set `no_drop = true`. Without it `method` silently becomes `drop` after 50
triggers in 30s, and a browser retrying blows through that in seconds — which
restores the very hang the rules remove.

They sit after the peer and private rules, so the `wg` leg (`fd9f:6666::/64`)
and LAN v6 are untouched; only proxied traffic loses QUIC and v6.

**Lesson:** DNS-level mitigations only bind clients that use the system
resolver. Anything with its own DoH — Firefox by default, Chrome's Secure DNS —
needs the route layer.

### 7e. Tailscale: CGNAT is not `ip_is_private`

Symptom after the mac came up on the subscription: Tailscale "stopped working",
but confusingly `tailscale ping fedorivns-homelab` still answered while
`ssh fedorivn@fedorivns-homelab` died with `Connection closed`.

Cause: the tailnet's v4 range is **RFC6598 CGNAT (100.64.0.0/10)**, and Go's
`netip.Addr.IsPrivate()` — what `ip_is_private` uses — covers RFC1918 plus
`fc00::/7` and nothing else. So tailnet v4 matched no rule, fell through to
`route.final`, and left through a subscription node that cannot reach a
100.64/10 peer.

The split in symptoms is diagnostic:

* `tailscale ping` runs in userspace inside `tailscaled` and never traverses
  these rules, so it keeps working and makes the tailnet look healthy.
* `ssh` goes through the tun, which completes the TCP handshake locally before
  it knows the far end is unreachable — the same false-positive documented in
  the reachability memo — then the proxied connection goes nowhere.

Fix: an explicit direct rule for `100.64.0.0/10` and `fd7a:115c:a1e0::/48`,
placed with the `wg` peer rule. The v6 half is already private, but naming it
keeps the pair together and, critically, keeps it ahead of the `ip_version = 6`
reject from 7d.

MagicDNS needs nothing: `100.100.100.100/32` is a more specific route than the
tun's default, so those queries go to Tailscale's own interface and are never
hijacked. (They *do* break while Happ holds the default route — that is a Happ
artifact, not this config.)

## 8. The `http_client` bug (fixed here)

The generator used to emit `http_client.detour = "direct"` for rule-sets. On
1.14.1 that is **fatal at service start**:

```
FATAL start service: initialize rule-set: detour to an empty direct outbound makes no sense
```

`sing-box check` passes it, so the build-time gate in `modules/nixos/sing-box.nix`
cannot catch it — the same trap the comment at `modules/nixos/sing-box.nix:47`
already documents for DNS servers.

The fix, now in the generator as `ruleSetHttpClientTag`, is a top-level tagged
HTTP client — verified to both silence the deprecation warning and genuinely
dial direct:

```json
"http_clients": [ { "tag": "rs-http" } ],
"route": { "rule_set": [ { "...": "...", "http_client": "rs-http" } ] }
```

An inline `"http_client": {}` is **wrong** — rule-set downloads then follow
`route.final` straight into the tunnel.

### Why there is no dialect switch

The generator used to take `ruleSetDetourField` so each host could pick
`http_client` (SFM) or the older `download_detour` (nixpkgs). That split is
gone: **both consumers are >= 1.14.0** — nixpkgs 1.14.1, and SFM
1.14.0-alpha.32, whose `option/http.go` `HTTPClientOptions.UnmarshalJSON`
already accepts the bare-string tag form. Verified against the alpha.32 tag, not
assumed.

Removing it also silenced the homelab's `download_detour` deprecation warning
(deprecated 1.14.0, removed 1.16.0), so that migration is done rather than
pending.

---

## 9. Spec impact (applied)

`spec.md` has been updated: "Default traffic via personal WireGuard" became
"Default traffic via subscription proxy", with added scenarios for urltest
selection and for `wg` still carrying peer traffic. A requirement covering the
refresh command was added, and the sops requirement extended to the node
definitions.

---

## 10. Verification

Done against the **actually rendered** profiles (generator output with the real
sops value substituted), with the tun inbound swapped for a `mixed` inbound so
it runs unprivileged:

| Check | Result |
| --- | --- |
| `personal.json` renders + `sing-box check` | pass, 9 outbounds, `final = proxy` |
| `corp.json` renders + `sing-box check` | pass, 10 outbounds, `final = proxy` |
| `personal.json` **runs** | clean start, no fatal/error/deprecation |
| `corp.json` **runs** | clean start (20s, no fatal) |
| Egress | `193.149.129.84` — the `ameno/hysteria2-nl2` node |
| `gosuslugi.ru` | `outbound/direct[direct]` |
| Homelab rendered template runs | valid, clean start, egress `193.149.129.84` |
| Homelab store template leak check | clean |
| Homelab `checkable` + `sing-box check` | pass (`system` stack, `sbtun0`) |
| Mac `sing-box-check-{personal,corp}` derivations | **build** — the gate exists on the mac now too |
| Store template leak check | outbounds are `["direct", <opaque>]`; no provider/node/credential strings |
| Rendered template substituted + run | valid, clean start, egress `95.179.143.189` (urltest picked a different node than the first run — the group works) |
| Refresh recipe | idempotent; aborts on empty fetch and on HTTP error |

`check` alone is not enough: the `http_client.detour` bug in §7 passes `check`
and only fails at start. Always run the profile, not just check it.

Note: these were run on a machine with a Happ VPN active, so the `direct` leg
egressed through Happ. That does not affect the routing-decision results — the
proxy egress IP matches a subscription node exactly, and `direct` was confirmed
from the outbound sing-box chose. **Happ's tun and SFM's tun conflict; disable
Happ before testing the activated profile.**

`ya.ru`, `sberbank.ru` and `mail.ru` route via the proxy rather than direct.
That is **correct**, not a bug: the ruleset is
`geosite-ru-available-only-inside`, and those three are reachable from outside
Russia.
