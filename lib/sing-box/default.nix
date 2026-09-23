# Base sing-box split-tunnel config generator (personal profile).
#
# Returns an *attrset*. Both hosts render it the same way — through
# ./render.nix, into a sops-nix template whose secrets are
# `config.sops.placeholder."..."` strings — and differ only in where the result
# lands: `~/.sing-box/*.json` for SFM on the mac, `/etc/sing-box/config.json`
# for the system service on the homelab. ./render.nix explains why NixOS does
# not use `services.sing-box.settings` for this.
#
# The shape is: everything outside the tunnel that should stay outside (RU-only
# sites by rule-set, private IPs), everything else through the default outbound.
# Profiles that need more than this patch the returned attrset — see ./corp.nix.
#
# The default outbound is the `proxy` selector over subscription nodes. It used
# to be a WireGuard endpoint (`snejugal.ru`), which is banned as a general exit;
# the endpoint has since been removed entirely, so there is no WireGuard leg and
# no peer route here any more. See
# openspec/specs/split-tunnel-router/design-notes.md.
{ tunStack ? "gvisor"
, tunStrictRoute ? true
, tunInterfaceName ? null
  # How the host resolves names that must not go through the tunnel (RU-inside
  # rule-set, the WireGuard peer, rule-set downloads) — and, via
  # `route.default_domain_resolver`, how sing-box resolves domains it needs
  # itself, such as the `urltest` probe URL.
  #
  # NOT `type = "local"`. That defers to the system resolver, which under an
  # auto_route tun is sing-box itself: the query leaves the host, gets captured
  # by the tun inbound, comes back through `hijack-dns`, and falls to
  # `dns.final` = `tunnel-dns`, whose detour is the `proxy` selector — backed by
  # a `urltest` that cannot pick a node until it resolves its probe URL. That is
  # a startup deadlock: no DNS until the proxy is ready, no proxy until DNS
  # works, so nothing resolves at all. It only became reachable when the default
  # outbound stopped being a WireGuard endpoint (which needs no health probe, so
  # it was always "ready"), which is why this used to work on macOS.
  #
  # Talking to an upstream directly avoids the cycle. No `detour` here,
  # deliberately: a DNS server without one dials with sing-box's own default
  # dialer (common/dialer: `Detour == ""` -> NewDefault), which is exactly what
  # an option-less `direct` outbound does — so since 1.12 `detour = "direct"` is
  # a *fatal* error, "detour to an empty direct outbound makes no sense". This is
  # not the same as falling through to `route.final`: DNS servers never traverse
  # the route rules, so these queries stay off the tunnel, which is the whole
  # point of `direct-dns`. `sing-box check` catches none of this — it validates
  # schema only, and detours resolve at service start.
  #
  # DoH (port 443), not plain UDP:53. Measured on the mac's network: `dig` to
  # 1.1.1.1, 8.8.8.8 *and* 77.88.8.8 all time out, while DoH to the same address
  # answers — plain DNS egress is filtered, which is routine on Russian ISPs. A
  # `type = "udp"` direct resolver is therefore dead exactly where this config
  # has to work, taking RU-inside resolution and `default_domain_resolver` with
  # it. Given as an IP, so it needs no bootstrap resolution of its own.
, directDns ? { tag = "direct-dns"; type = "https"; server = "1.1.1.1"; }
  # Subscription nodes that carry everything the tunnel takes. A marker string
  # the consumer substitutes for a JSON *array* of outbounds (see
  # modules/home/sing-box.nix).
  #
  # The substituted array holds the nodes *and* the `proxy-auto` urltest and
  # `proxy` selector over them — not just the raw nodes. Two reasons, both
  # learned the hard way: naming the nodes here would put their tags
  # (`ameno/reality-de1`, …) in the world-readable Nix store, which leaks the
  # provider and the rough geography even though the credentials stay encrypted;
  # and it would force a second, hand-maintained copy of the tag list that only
  # fails at activation when it drifts. Keeping the groups inside the secret
  # means the store sees only `proxy` and `direct`.
  #
  # So the substituted value must define a `proxy` outbound — `route.final` and
  # the tunnel DNS server both name it. Required: every host runs this shape,
  # and lib/sing-box/render.nix is the only caller.
, proxyOutbounds
}:
let
  # Rule-set downloads must not go through the tunnel, and saying
  # `detour = "direct"` is not how you express that on 1.14: pointing a detour at
  # an option-less `direct` outbound is rejected ("detour to an empty direct
  # outbound makes no sense") — fatal at service start, and `sing-box check` does
  # *not* catch it, so a build-time check will happily pass a config that cannot
  # boot. The 1.14 spelling is a tagged top-level HTTP client, which dials with
  # the default dialer. An inline `http_client = { }` is not equivalent: that is
  # the deprecated implicit default, and it routes downloads through
  # `route.final` — i.e. straight into the tunnel.
  #
  # Both consumers are 1.14.1 (nixpkgs; SFM via the `sfm` cask, whose
  # `HTTPClientOptions.UnmarshalJSON` accepts the bare-string tag form), so
  # there is no older `download_detour` dialect to fall back to.
  ruleSetHttpClientTag = "rule-set-http";

  ruleSet = tag: url: {
    type = "remote";
    inherit tag url;
    format = "binary";
    update_interval = "1d";
    http_client = ruleSetHttpClientTag;
  };
in
{
  log = {
    level = "info";
    timestamp = true;
  };

  dns = {
    servers = [
      {
        tag = "tunnel-dns";
        type = "udp";
        server = "1.1.1.1";
        detour = "proxy";
      }
      directDns
    ];
    rules = [
      {
        rule_set = "geosite-ru-inside";
        server = directDns.tag;
      }
    ];
    final = "tunnel-dns";

    # The subscription nodes have no IPv6 egress — a request for a v6-only host
    # through them fails outright. Handing clients an AAAA they cannot use is
    # worse than not having one: curl falls back to v4 quickly, but browsers
    # follow happy-eyeballs into the dead v6 path and stall, which reads as
    # "the internet is broken in Chrome but `curl` is fine". The provider's own
    # generated config sets ipv4_only for the same reason.
    #
    # `dns.strategy` is global: per-rule `strategy` is deprecated in 1.14 and
    # removed in 1.16. It costs v6 on the direct (RU) leg too, which is a real
    # but small loss next to a browser that hangs.
    strategy = "ipv4_only";
  };

  inbounds = [
    ({
      type = "tun";
      tag = "tun-in";
      # Link-local sink for the tun device itself; nothing outside the host
      # addresses it, so it is the same everywhere.
      address = [
        "172.19.0.1/30"
        "fdfe:dcba:9876::1/126"
      ];
      mtu = 1420;
      auto_route = true;
      strict_route = tunStrictRoute;
      stack = tunStack;
      # Keep the tailnet out of the tun entirely.
      #
      # `auto_route` otherwise installs routes that sit on top of Tailscale's:
      # observed on the mac was a /32 for a tailnet peer pointing at the tun and
      # flagged reject (`UHW3Ig ... utun7 !`), with Tailscale's own 100.64/10
      # route gone. Traffic then dies in the kernel *before* sing-box sees it,
      # so the `ip_cidr` route rule below cannot help — and even if it could,
      # `direct` + `auto_detect_interface` binds the physical interface, which
      # is equally wrong for an address that only exists inside Tailscale.
      #
      # Excluding the prefixes leaves the OS routing them to Tailscale's own
      # interface, which is the only thing that can deliver them.
      route_exclude_address = [
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
      ];
    } // (if tunInterfaceName == null then { } else { interface_name = tunInterfaceName; }))
  ];

  # `proxyOutbounds` is a marker the consumer replaces with the node array plus
  # the `proxy-auto` urltest and `proxy` selector built over it, so it is spliced
  # in as-is rather than merged. The selector it defines names `direct` from this
  # file — tags resolve across the whole config, so that is fine, and it keeps
  # `direct` a one-click bypass in the SFM dashboard.
  outbounds = [
    {
      type = "direct";
      tag = "direct";
    }
    proxyOutbounds
  ];

  # Keeps rule-set downloads off the tunnel — see `ruleSetHttpClientTag`.
  http_clients = [{ tag = ruleSetHttpClientTag; }];

  route = {
    rules = [
      { action = "sniff"; }
      {
        protocol = "dns";
        action = "hijack-dns";
      }
      # Anything below here selects an outbound; ./corp.nix relies on that to
      # insert its own rule ahead of them.

      # Tailscale. The tailnet's v4 range is RFC6598 CGNAT, which `ip_is_private`
      # does *not* cover — Go's netip.Addr.IsPrivate() is RFC1918 plus fc00::/7
      # only. Without this rule tailnet traffic falls through to `route.final`
      # and leaves through a subscription node, which cannot reach a 100.64/10
      # peer. The symptom is confusing: `tailscale ping` keeps working, because
      # it runs in userspace inside tailscaled and never touches these rules,
      # while `ssh` to the same host dies with "Connection closed" — the tun
      # answers the handshake locally and the proxied connection then goes
      # nowhere.
      #
      # The v6 half is already private, but naming it keeps the pair together and
      # immune to reordering — in particular it must stay ahead of the
      # `ip_version = 6` reject below.
      {
        ip_cidr = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
        outbound = "direct";
      }
      {
        rule_set = [
          "geosite-ru-inside"
          "geoip-ru"
        ];
        outbound = "direct";
      }
      {
        ip_is_private = true;
        outbound = "direct";
      }
      # Everything below here would go to the proxy. Two things the browser does
      # and `curl` does not have to be killed before they get there, both of
      # which present as "google.com hangs in the browser, `curl` is fine".
      #
      # `no_drop` on both: without it `method` silently becomes `drop` after 50
      # triggers in 30s, and a browser retrying blows through that in seconds —
      # which would restore the exact hang these rules remove.

      # 1. QUIC / HTTP3. Google advertises `alpn=h2,h3` in its HTTPS RR, so
      # Firefox and Chrome both open HTTP/3 over UDP:443; the system `curl` has
      # no HTTP/3 support at all, which is why the two disagree. The
      # subscription's vless nodes carry no `packet_encoding`, so their UDP
      # relay does not carry QUIC properly and the attempt hangs rather than
      # failing. Rejecting makes the fallback to h2 immediate.
      {
        network = "udp";
        port = [ 443 ];
        action = "reject";
        no_drop = true;
      }

      # 2. IPv6. The nodes have no v6 egress, so a v6 connection through them
      # black-holes. `dns.strategy = "ipv4_only"` stops *our* resolver handing
      # out AAAA, but a browser that resolves for itself — Firefox's DoH is on
      # by default — never asks us, gets an AAAA anyway, and stalls on
      # happy-eyeballs. Rejecting at the route level covers the client-side
      # resolver case the DNS strategy cannot reach.
      #
      # Both rules sit after the tailnet and private rules, so LAN v6 keeps
      # working; only proxied traffic loses QUIC and v6.
      {
        ip_version = 6;
        action = "reject";
        no_drop = true;
      }
    ];
    rule_set = [
      (ruleSet "geosite-ru-inside"
        "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geosite/geosite-ru-available-only-inside.srs"
      )
      (ruleSet "geoip-ru"
        "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geoip/geoip-ru.srs"
      )
    ];
    final = "proxy";
    auto_detect_interface = true;
    default_domain_resolver = directDns.tag;
  };

  # `store_fakeip` is not implied by `enabled`, and only ./corp.nix has a FakeIP
  # server — but it belongs here, because the profiles share this file and a
  # FakeIP address that outlives its mapping is the worst failure the router
  # has. Without it the mappings are in-memory: sing-box restarts (a profile
  # reload, an SFM update, a laptop wake), the browser still holds
  # `198.18.x.x` from before, and every connection to it dies with
  #
  #   ERROR router: missing fakeip record, try enable `experimental.cache_file`
  #
  # The allocator also restarts at the bottom of `inet4_range`, so after a
  # restart the same address is handed to whichever corp domain asks first and
  # a stale browser entry silently points at a *different* host. Firefox caches
  # DNS hard and reuses connections, so it wears all of this while `curl`,
  # which re-resolves per invocation, looks fine.
  experimental.cache_file = {
    enabled = true;
    store_fakeip = true;
  };
}
