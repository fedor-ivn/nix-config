# The pieces every sing-box profile is built from.
#
# Profiles (./profiles/) assemble these into a whole config themselves rather
# than filling hooks in a shared skeleton: `dns.rules` and `route.rules` are
# ordered match-lists, and spelling them out at the call site is what makes a
# profile's routing readable. What must not vary — the order of the prelude and
# the fallthrough tail, the scalars in `dnsDefaults`/`routeDefaults` — is a
# named group here, so a profile composes around it instead of retyping it.
{ lib, platform }:
let
  hosts = {
    darwin = {
      tunStack = "gvisor";
      tunStrictRoute = true;
      tunInterfaceName = null;
      tunRouteExcludeAddress = [ ];
    };
    nixos = {
      # `system` beats gvisor on Linux, and strict_route installs firewall rules
      # that can cut off inbound connections to a box that serves them (SSH,
      # Tailscale) — plain auto_route already keeps LAN/tailnet routes, which are
      # more specific than the tun's default route.
      tunStack = "system";
      tunStrictRoute = false;
      tunInterfaceName = "sbtun0";
      tunRouteExcludeAddress = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
    };
  };

  host = hosts.${platform};

  # Rule-set downloads must not go through the tunnel. `detour = "direct"` is
  # not how you say that on 1.14 — pointing a detour at an option-less `direct`
  # outbound is rejected at service start, and `sing-box check` does not catch
  # it — and an inline `http_client = { }` is the deprecated implicit default,
  # which routes downloads through `route.final`, i.e. into the tunnel. A tagged
  # top-level client dials with the default dialer.
  ruleSetHttpClientTag = "rule-set-http";

  ruleSet = tag: url: {
    type = "remote";
    inherit tag url;
    format = "binary";
    update_interval = "1d";
    http_client = ruleSetHttpClientTag;
  };

in
rec {
  inherit ruleSet;

  log = {
    level = "info";
    timestamp = true;
  };

  # ---------------------------------------------------------------- DNS ----

  # How the host resolves anything that must not go through the tunnel (RU-inside
  # rule-set, rule-set downloads) — and, via `default_domain_resolver`, such names
  # as the `urltest` probe URL.
  #
  # NOT `type = "local"`: under an auto_route tun the system resolver *is*
  # sing-box, so the query leaves the host, gets captured by the tun inbound,
  # comes back through `hijack-dns` and falls to `dns.final` = `tunnel-dns`,
  # whose detour is `proxy` — backed by a urltest that cannot pick a node until
  # it resolves its probe URL. Startup deadlock: no DNS until the proxy is ready,
  # no proxy until DNS works.
  #
  # No `detour`: a server without one dials with sing-box's default dialer, which
  # is what an option-less `direct` outbound does — hence `detour = "direct"`
  # being fatal since 1.12. DNS servers never traverse the route rules, so these
  # queries stay off the tunnel, which is the point of the name.
  #
  # DoH, not plain UDP:53: measured here, plain DNS to 1.1.1.1/8.8.8.8/77.88.8.8
  # all times out while DoH to the same address answers — egress filtering that
  # is routine on Russian ISPs. Given as an IP, so it needs no bootstrap.
  directDns = {
    tag = "direct-dns";
    type = "https";
    server = "1.1.1.1";
  };

  tunnelDns = {
    tag = "tunnel-dns";
    type = "udp";
    server = "1.1.1.1";
    detour = "proxy";
  };

  # Every profile's DNS servers, in order. A profile prepends its own.
  dnsServers = [ tunnelDns directDns ];

  # The tail of `dns.rules`. A profile's own rules go *ahead* of this: matched
  # later, a name that needs special handling would hit the RU check first.
  dnsFallthrough = [{
    rule_set = "geosite-ru-inside";
    server = directDns.tag;
  }];

  # Scalars that are the same in every profile by definition. The subscription
  # nodes have no IPv6 egress, so an AAAA handed to a client is a stall: curl
  # falls back to v4, browsers follow happy-eyeballs into the dead path.
  # `strategy` is global because per-rule `strategy` is deprecated in 1.14 and
  # removed in 1.16; it costs v6 on the direct leg too.
  dnsDefaults = {
    final = tunnelDns.tag;
    strategy = "ipv4_only";
  };

  # ----------------------------------------------------------- inbounds ----

  # Link-local sink for the tun device itself; nothing outside the host
  # addresses it.
  tunInbound = {
    type = "tun";
    tag = "tun-in";
    address = [
      "172.19.0.1/30"
      "fdfe:dcba:9876::1/126"
    ];
    mtu = 1420;
    auto_route = true;
    strict_route = host.tunStrictRoute;
    stack = host.tunStack;
    # Only set where it means "leave this prefix alone". On Linux it is
    # load-bearing: `auto_route` is policy routing, and carving the prefixes
    # out of sing-box's own table is what lets lookups fall through to `main`,
    # where Tailscale's routes live.
    #
    # macOS (NetworkExtension) turns each prefix into a *kernel* route pinned
    # to the physical interface, at the same prefix length as Tailscale's — a
    # route fight, last writer wins, so a tunnel restart black-holes the
    # tailnet until `tailscale up` makes tailscaled the last writer again. So
    # macOS passes `[ ]` and relies on specificity: the tun's route is
    # `default`, the tailnet's is narrower and wins with nothing competing.
  } // lib.optionalAttrs (host.tunRouteExcludeAddress != [ ]) {
    route_exclude_address = host.tunRouteExcludeAddress;
  } // lib.optionalAttrs (host.tunInterfaceName != null) {
    interface_name = host.tunInterfaceName;
  };

  # ---------------------------------------------------------- outbounds ----

  # Named from profiles and from the subscription's own `proxy` selector — tags
  # resolve across the whole config, which keeps `direct` a one-click bypass in
  # the SFM dashboard.
  direct = {
    type = "direct";
    tag = "direct";
  };

  httpClients = [{ tag = ruleSetHttpClientTag; }];

  # -------------------------------------------------------- route rules ----

  # Actions, not outbound picks. Always first: a rule that selects an outbound
  # before sniffing has no domain to match on.
  prelude = [
    { action = "sniff"; }
    {
      protocol = "dns";
      action = "hijack-dns";
    }
  ];

  # The direct-then-reject tail, in order, and it always goes *last*: a profile's
  # own rules go ahead of it, or they never match — a domain that reaches these
  # hits the RU/private checks and then `route.final`, i.e. the tunnel.
  #
  # Tailscale's v4 range is RFC6598 CGNAT, which `ip_is_private` does *not* cover
  # (Go's IsPrivate is RFC1918 + fc00::/7 only). Without the first rule the
  # tailnet falls through to `route.final` and leaves via a subscription node,
  # which cannot reach a 100.64/10 peer — while `tailscale ping` keeps working,
  # because it runs in userspace and never touches these rules.
  #
  # The two rejects are things browsers do that `curl` does not, both presenting
  # as "the site hangs in the browser but `curl` is fine". `no_drop` on both:
  # without it the method silently becomes `drop` after 50 triggers in 30s, and a
  # retrying browser blows through that in seconds.
  #
  # 1. QUIC/HTTP3 — Google advertises `alpn=h2,h3`, so Firefox and Chrome open
  #    HTTP/3 over UDP:443, while curl has no HTTP/3 at all. The nodes carry no
  #    `packet_encoding`, so their UDP relay hangs on QUIC instead of failing.
  # 2. IPv6 — the nodes have no v6 egress. `dns.strategy = "ipv4_only"` stops
  #    *our* resolver handing out AAAA, but a browser resolving for itself
  #    (Firefox DoH) never asks us; rejecting here covers that case. Both rejects
  #    sit after the tailnet and private rules, so LAN v6 keeps working.
  fallthrough = [
    {
      ip_cidr = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
      outbound = "direct";
    }
    {
      rule_set = [ "geosite-ru-inside" "geoip-ru" ];
      outbound = "direct";
    }
    {
      ip_is_private = true;
      outbound = "direct";
    }
    {
      network = "udp";
      port = [ 443 ];
      action = "reject";
      no_drop = true;
    }
    {
      ip_version = 6;
      action = "reject";
      no_drop = true;
    }
  ];

  ruleSets = [
    (ruleSet "geosite-ru-inside"
      "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geosite/geosite-ru-available-only-inside.srs"
    )
    (ruleSet "geoip-ru"
      "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geoip/geoip-ru.srs"
    )
  ];

  # As with `dnsDefaults`: the same in every profile by definition.
  routeDefaults = {
    rule_set = ruleSets;
    final = "proxy";
    auto_detect_interface = true;
    default_domain_resolver = directDns.tag;
  };

  # ------------------------------------------------------- experimental ----

  # `store_fakeip` is not implied by `enabled`, and it is shared rather than
  # corp-only because a FakeIP address outliving its mapping is the worst failure
  # this router has: the mappings are otherwise in-memory, so any restart
  # (profile reload, SFM update, laptop wake) leaves a browser holding a
  # `198.18.x.x` that now points at a *different* host — or at nothing. Both
  # cases log `missing fakeip record`.
  experimental.cache_file = {
    enabled = true;
    store_fakeip = true;
  };
}
