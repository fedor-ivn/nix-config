## Context

`fedorivns-mbp` is the daily driver and needs to reach corp internal hosts
under `*.tcsbank.ru`. The only machine with corp network reachability is a
corp laptop whose endpoint stack (Cisco Secure Client Always-On, Kaspersky,
SkyGuard DLP, Forcepoint/Check-Point) **silently drops unsolicited inbound
TCP** while permitting ICMP and outbound. Empirically:

- `ping` to the corp laptop succeeds; `ssh`/`nc` to port 22 time out (SYN
  dropped before reaching `sshd`, which is up and listening).
- The block correlates with the corp VPN/agents being active — it is policy,
  centrally pushed, and not something we control or should fight.
- Outbound from the corp laptop works (the VPN itself needs it).
- The corp resolver `10.219.194.5` answers DNS over **UDP only**; TCP/53
  hangs.

The personal egress is a WireGuard endpoint (`62.84.97.10:51830`). The
requirement is a *split*: only `*.tcsbank.ru` and `*.t-tech.team` ride the
corp path; everything else rides WireGuard.

Current state: an untracked `singbox.json` at the repo root with cleartext
WireGuard keys, plus a hand-typed SSH command. This design makes it
declarative in the flake.

## Goals / Non-Goals

**Goals:**

- A reproducible, flake-managed split tunnel on `fedorivns-mbp`.
- `*.tcsbank.ru` and `*.t-tech.team` reachable from the Mac via the corp
  laptop; all other traffic via personal WireGuard.
- Work *with* the corp laptop's outbound-only constraint — no inbound
  listener relied upon, no agent bypass.
- WireGuard secrets in sops, not cleartext; `singbox.json` generated.
- Mac-side resilience (auto-reconnect) without manual babysitting.

**Non-Goals:**

- Installing third-party software on the corp laptop, or managing it from
  nix-config. (Enabling built-in Remote Login + authorizing the Mac's key and
  running the documented on-demand dial are the only corp-side setup; all
  stock macOS.)
- Evading, disabling, or detecting-around the corp security agents.
- Routing non-corp traffic through corp egress.
- Rollout to other hosts.

## Decisions

### Decision 1: Reverse tunnel (corp dials out), not inbound to corp

The corp agents block inbound, so we invert the direction: the **corp laptop
initiates an outbound SSH connection** to the Mac and reverse-forwards a
port. Outbound is the one thing reliably permitted (the VPN depends on it).

- *Alternative — expose a proxy/sshd on the corp laptop:* impossible; that's
  exactly the inbound the agents drop.
- *Alternative — VPS rendezvous:* both sides dial a public VPS. Viable
  fallback if corp blocks LAN-to-LAN too, but adds a third host and exposes a
  relay. We're on the same LAN (`192.168.1.0/24`), and corp→Mac outbound on
  port 22 tested open, so direct is simpler. VPS stays documented as the
  fallback.

### Decision 2: Stock-`ssh` two-hop SOCKS (corp egress requires it)

Two stock-`ssh` sessions, one per machine:

```
# 1) corp laptop, on demand — reverse-forward its own sshd to the Mac
ssh -N -R 2222:localhost:22 \
  -o ConnectTimeout=3 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  fedorivn@fedorivns-mbp.local

# 2) Mac, auto-restart — dial back through it, open SOCKS that egresses from corp
ssh -N -D 127.0.0.1:1080 -p 2222 \
  -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=accept-new \
  <corp-user>@localhost
```

Session 1 makes the corp laptop's sshd reachable on the Mac at
`127.0.0.1:2222`. Session 2 is an `ssh -D` whose **server is the corp laptop**
(reached via that forward), so the SOCKS proxy's outbound connections are made
**from the corp laptop** — the required egress. sing-box talks to
`127.0.0.1:1080` as before. Scripts: `scripts/corp-tunnel.sh` (corp) and
`scripts/corp-tunnel-mac.sh` (Mac).

**Why not one-hop (the original, broken design).** A single corp-side
`ssh -D 127.0.0.1:1080 -R 127.0.0.1:1080:127.0.0.1:1080 mac` was tried first
and is **architecturally inverted**: `ssh -D` opens its outbound connections
from the SSH *server*, and in a corp→Mac dial the server is the **Mac**. So
that SOCKS egressed from the Mac (via WireGuard), not the corp laptop —
verified empirically: `curl --socks5-hostname 127.0.0.1:1080 https://ifconfig.me`
through it returned the Mac's WireGuard exit (`62.84.97.10`), identical to no
bridge, and corp-internal hosts died mid-TLS-handshake (`SSL_ERROR_SYSCALL`).
"stock-ssh-only", "single session", and "corp egress" are mutually exclusive:
the one session must connect *to* the Mac (corp can only dial out), and `-D`
always egresses from that far end. Hence two sessions.

- *Alternative — `microsocks`/dante on corp + single `-R 1080`:* a real SOCKS
  daemon on corp makes its own local outbound connections (correct egress) in
  one corp session, no Mac consumer, no corp sshd. Rejected: requires running
  a non-stock binary on the locked-down corp laptop.
- *Alternative — static per-host `-R host:port` forwards:* `-R` resolves its
  target on the corp (client) side, so `-R 8443:wiki.tcsbank.ru:443` does
  egress from corp with stock ssh and one session. Rejected as the primary:
  only covers an enumerated host list (no `*.tcsbank.ru` wildcard) and forces
  sing-box to DNAT names→ports. Kept as a documented fallback for a fixed set
  of hosts.

**New requirement this introduces:** the corp laptop must run its own sshd
(Remote Login on) and authorize the Mac's key, since session 2 authenticates
*to* the corp laptop over the tunnel. (Session 1 still authenticates corp→Mac
as before.)

### Decision 3: FakeIP for corp domains, not a DNS-server detour

The Mac cannot itself query the corp resolver: `10.219.194.5` is UDP-only and
`ssh -D` proxies TCP only, so a `type:tcp … detour:socks` DNS server hangs
(verified). Instead, **FakeIP**: sing-box hands the app a placeholder
`198.18.0.0/15` address for corp domains (`*.tcsbank.ru`, `*.t-tech.team`);
when the app connects, sing-box maps it back to the hostname and passes the
**name** to the SOCKS outbound, so the corp laptop resolves it locally over UDP.
This mirrors the proven `curl --socks5-hostname` path.

- *Alternative — `type:tcp` corp DNS over the SOCKS detour:* fails, corp DNS
  has no TCP.
- *Alternative — resolve on Mac via WireGuard DNS:* can't see corp-internal
  zones.

### Decision 4: sing-box TUN with `auto_route`, ordered rules

A `tun` inbound with `auto_route` + `strict_route` captures system traffic;
rule order is: `sniff` → hijack DNS → `domain_suffix [tcsbank.ru, t-tech.team] → socks-tbank`
→ `ip_is_private → direct` → final `wg`. `sniff` is a route **action**
(sing-box ≥1.11; the legacy inbound `sniff` field is removed in 1.13). DNS
hijack uses `protocol:dns`. `default_domain_resolver` is set (required since
1.12). gvisor stack for portability on macOS.

### Decision 5: Secrets via sops, generated config

WireGuard `private_key`/`pre_shared_key` move to `secrets.yaml`;
`singbox.json` is rendered by nix from a template that interpolates the
decrypted secret at activation, so no key sits cleartext in the working tree
or world-readable in the Nix store. The untracked root `singbox.json` is
removed.

### Decision 6: Add Tinkoff LBaaS Kubernetes CA to the Mac System keychain

Some corp services — observed on `*.t-tech.team` (e.g. `copilot.t-tech.team`)
— serve TLS certificates signed by Tinkoff Bank's internal **LBaaS Kubernetes
CA** (`CN=LBaaS Kubernetes CA; O=Tinkoff Bank; OU=k8s-admins`). This is the CA
used to issue certs for services running behind internal Kubernetes load
balancers. `*.tcsbank.ru` services use publicly-signed certificates (GlobalSign)
and need no special handling.

The Mac's default trust store does not include the LBaaS CA, so connections to
affected `*.t-tech.team` services fail with `unable to get local issuer
certificate`. The fix is to add the LBaaS Kubernetes CA to the macOS System
keychain:

- Export the CA cert from the corp laptop's keychain: `security
  find-certificate -c "LBaaS Kubernetes CA" -p /Library/Keychains/System.keychain`
- Add it to the Mac: `sudo security add-trusted-cert -d -r trustRoot -k
  /Library/Keychains/System.keychain <lbaas-ca.pem>`

- *Alternative — `--insecure` / disable verification:* unacceptable for normal
  use; masks real certificate problems.
- *Alternative — scoped per-tool trust (`--cacert` bundle, dedicated browser
  profile):* unnecessary friction. The CA is already narrow by nature — it signs
  certs only for Tinkoff's internal k8s services, all of which are reachable
  exclusively through the corp bridge anyway.

### Decision 7: Corp-side on-demand self-healing command; Mac-side launchd `ssh` service

The corp laptop's outbound `ssh` (Decision 2 session 1) is run **on demand as
a bare command** (`scripts/corp-tunnel.sh`), not registered with launchd. The
user starts it when they need corp access and Ctrl-C's it when done — but
while running it **auto-reconnects** so a brief sleep / Wi-Fi blip on the
personal Mac heals itself without re-running anything.

**Reconnect with capped backoff, not a fixed interval.** Because autossh is
not stock macOS and adding software to the locked-down corp laptop is
undesirable (Tailscale and WG are explicitly prohibited), the corp side uses a
stock-`ssh` bash loop with **exponential backoff + jitter** (`MIN=5 s`,
`MAX=300 s`). The loop distinguishes the two exit cases by session lifetime:
- an **established** session that drops (e.g. a momentary Mac sleep — detected
  via `ServerAliveInterval=30`/`CountMax=3`, ~90 s) resets backoff to the
  minimum, so recovery is prompt;
- a **quick failure** (`ConnectTimeout=3`, Mac off-LAN) grows the backoff up to
  the cap.

This is the deliberate middle ground on the detection-surface trade-off. An
always-on agent retrying every ~33 s, 24/7, is a textbook C2-beacon pattern
the corp agents (Forcepoint/Cisco/SkyGuard) flag. Two things keep this from
being that: (1) it runs **only while the user has it started** — nothing dials
when not doing corp work, and there is no launchd artifact that survives
reboot; (2) while running, backoff+jitter makes a long absence **sparse and
irregular**, not a tight fixed cadence. Fast recovery from a brief drop;
sparse during a genuine outage.

**Why a bare command, not a LaunchAgent.** A LaunchAgent — even loaded
`Disabled` — is a *persistent, launchd-registered artifact* on a monitored
machine: a durable `~/Library/LaunchAgents/*.plist` that corp MDM/EDR can
enumerate and that survives reboots. The bare command leaves no registration;
its footprint is shell history. It is also the only form faithful to
Decision 2's "no third-party software/service persisted on corp" constraint.
The choice only affects on-machine footprint, not whether the activity is
permitted (corp egress is TLS-intercepted/DLP-logged either way).

**Mac-side consumer = plain `ssh` under launchd `KeepAlive`.** Session 2 is the
opposite case: it runs on the Mac, our managed machine, and connects **only to
loopback** (`localhost:2222`), so continuous retry carries no beacon concern.
It is a nix-managed home-manager launchd agent (`modules/home/corp-tunnel.nix`,
gated on `me.isMainMachine`) running stock `ssh` — **no autossh and no backoff
loop**: launchd `KeepAlive` relaunches `ssh` whenever it exits, and
`ServerAlive` makes `ssh` exit on a dead link, so launchd is the supervisor.
launchd's ~10 s respawn throttle prevents a tight spin while `127.0.0.1:2222`
is still down; the agent self-heals as soon as the corp laptop dials in. The
corp account name comes from the private `secrets` flake input
(`corpTunnelUser`), so it stays out of the public repo.

- *Alternative — autossh on the Mac:* its only added value over `ssh` +
  launchd `KeepAlive` is detecting a hung-but-not-exited connection, which
  `ServerAlive` already forces to exit; rejected as an unneeded dependency.
- *Alternative — LaunchAgent on corp (always-on or `kickstart`):* a persistent
  enumerable artifact on the monitored machine that survives reboot, for no
  benefit over the self-healing bare command; rejected.
- *Alternative — fixed-interval corp retry (e.g. `KeepAlive` +
  `ThrottleInterval=30`):* the tight 24/7 beacon pattern; rejected in favour of
  backoff+jitter that only runs while started.
- *Alternative — autossh on the corp laptop:* third-party software on the
  locked-down machine; rejected. The bash backoff loop gives the same
  self-healing with stock `ssh`.

Likewise the Mac-side sing-box router is a proper launchd **system service**
(root, for TUN; starts on boot; restarts on crash) — see Decision 4. On the
Mac everything is a managed service; only the corp-side dial is the on-demand
self-healing command.

## Risks / Trade-offs

- **Corp-side step is manual** → can't be automated from nix-config, and by
  Decision 7 it is deliberately on-demand (user kicks the dial when starting
  corp work); mitigate with a documented one-liner / hotkey binding.
- **Detection surface of the dial itself:** any periodic outbound SSH to an
  unmanaged `.local` host resembles C2 beaconing to the corp behavioral
  agents. On-demand triggering (Decision 7) keeps the dial sporadic and
  tied to real use rather than a 24/7 fixed-interval beacon — this is the
  primary reason an always-on agent was rejected.
- **Policy/visibility:** corp traffic is TLS-intercepted and DLP-logged; the
  tunnel is functional, not stealthy → keep scope to corp domains only;
  this is acceptable-use-dependent and the user's call.
- **LBaaS CA key management** → Tinkoff's internal CA is managed by k8s-admins
  rather than a public CA programme; a key compromise would allow signing for
  any domain. Practical risk is low — this is a bank's internal infrastructure
  team — and the CA is only encountered on services already routed through the
  corp bridge (Decision 6).
- **SOCKS is down until the corp laptop dials in** → expected with on-demand
  triggering; sing-box just retries corp destinations until `127.0.0.1:1080`
  exists. The Mac-side consumer tolerates the ordering: it keeps failing fast
  and relaunching until session 1 brings up `127.0.0.1:2222`, then connects.
- **Corp policy could tighten** (block LAN-to-LAN / outbound 22) → documented
  VPS-rendezvous fallback (Decision 1) and port-443 SSH variant.
- **FakeIP range collision** with a real service using `198.18.0.0/15` →
  unlikely (benchmark range); revisit if a real route needs it.
- **Secrets in Nix store:** even templated, ensure the render writes to a
  mode-600 path outside the store (activation script), not a store path.

## Migration Plan

1. Add WireGuard keys to `secrets.yaml`; drop the cleartext root
   `singbox.json` from the tree (and `.gitignore` it if kept transiently).
2. Land the modules (Mac-side consumer service + sing-box) on
   `fedorivns-mbp`; `just a`. Enable Remote Login on the corp laptop and
   authorize the Mac's key.
3. On the corp laptop, run the documented on-demand dial (`corp-tunnel.sh`,
   session 1); the Mac-side consumer (session 2) connects automatically.
4. Verify split: a corp domain loads and `curl --socks5-hostname … ifconfig.me`
   shows the **corp** egress, while plain `ifconfig.me` shows the WireGuard
   exit.
5. Rollback: disable the modules and `just a`; the corp-side SSH is
   ephemeral (Ctrl-C). Corp host-state to undo is only Remote Login +
   the authorized key, if desired.

## Open Questions

- Keep `198.18.0.0/15` FakeIP range or narrow it?
