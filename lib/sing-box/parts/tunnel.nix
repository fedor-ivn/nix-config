# Egress through the subscription: everything that exists because `route.final`
# is the `proxy` selector, or because of what its nodes cannot carry. A profile
# without the tunnel takes none of this — `tunnelDns` alone names `proxy`, which
# fails at service start when no such outbound exists, and `sing-box check` does
# not catch it (it does not resolve tags).
{ core }:
let
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
  # ---------------------------------------------------------------- DNS ----

  tunnelDns = {
    tag = "tunnel-dns";
    type = "udp";
    server = "1.1.1.1";
    detour = "proxy";
  };

  dnsServers = [ tunnelDns ];

  # The tail of `dns.rules`. A profile's own rules go *ahead* of this: matched
  # later, a name that needs special handling would hit the RU check first.
  dnsRules = [{
    rule_set = "geosite-ru-inside";
    server = core.directDns.tag;
  }];

  # The subscription nodes have no IPv6 egress, so an AAAA handed to a client is
  # a stall: curl falls back to v4, browsers follow happy-eyeballs into the dead
  # path. `strategy` is global because per-rule `strategy` is deprecated in 1.14
  # and removed in 1.16; it costs v6 on the direct leg too.
  dns = {
    final = tunnelDns.tag;
    strategy = "ipv4_only";
  };

  # -------------------------------------------------------- route rules ----

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
  # The two rejects (see `core.reject`) sit after the tailnet and private rules,
  # so LAN v6 keeps working:
  #
  # 1. QUIC — the nodes carry no `packet_encoding`, so their UDP relay hangs on
  #    QUIC instead of failing.
  # 2. IPv6 — the nodes have no v6 egress. `dns.strategy = "ipv4_only"` stops
  #    *our* resolver handing out AAAA, but a browser resolving for itself
  #    (Firefox DoH) never asks us; rejecting here covers that case.
  routeRules = [
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
    (core.reject core.quic)
    (core.reject { ip_version = 6; })
  ];

  ruleSets = [
    (ruleSet "geosite-ru-inside"
      "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geosite/geosite-ru-available-only-inside.srs"
    )
    (ruleSet "geoip-ru"
      "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geoip/geoip-ru.srs"
    )
  ];

  httpClients = [{ tag = ruleSetHttpClientTag; }];

  route = {
    rule_set = ruleSets;
    final = "proxy";
  };
}
