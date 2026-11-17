# The corp bridge: corp domains go over the reverse-SSH SOCKS bridge
# (127.0.0.1:1080) instead of the profile's egress, and reach it by FakeIP — the
# bridge's far side owns the routing, so the domains must be resolved *there*,
# not locally. Only hosts that actually run that bridge use a profile with this.
#
# Both rule lists go ahead of any egress rules: matched later, a corp domain
# would hit the RU checks and resolve through the tunnel's resolver instead of
# FakeIP, then leave through the tunnel instead of the bridge.
{ core }:
rec {
  domains = [
    "tcsbank.ru"
    "t-tech.team"
    "tcsgroup.io"
    "tbank.ru"
    "tinkoff.ru"
  ];

  # ---------------------------------------------------------------- DNS ----

  fakeipDns = {
    tag = "fakeip-dns";
    type = "fakeip";
    inet4_range = "198.18.0.0/15";
    inet6_range = "fc00::/18";
  };

  dnsServers = [ fakeipDns ];

  dnsRules = [
    # Browsers query the HTTPS/SVCB RRs (types 64/65) over the system resolver.
    # FakeIP only synthesizes A/AAAA, so these get black-holed and Firefox
    # stalls (NS_ERROR_NET_TIMEOUT, surfaced as a failed CORS request).
    # Forwarding them upstream instead would leak real ipv4hint/ipv6hint and
    # ECH config, letting the client bypass FakeIP and connect with an
    # encrypted SNI we cannot sniff — either way the domain_suffix route rule
    # below never fires and the request skips the bridge. Reject with a fast
    # empty answer so the client falls back to the FakeIP A/AAAA path.
    {
      query_type = [ 64 65 ];
      domain_suffix = domains;
      action = "reject";
    }
    {
      domain_suffix = domains;
      server = fakeipDns.tag;
    }
  ];

  # ---------------------------------------------------------- outbounds ----

  socksBridge = {
    type = "socks";
    tag = "socks-tbank";
    server = "127.0.0.1";
    server_port = 1080;
    version = "5";
  };

  # -------------------------------------------------------- route rules ----

  # After the prelude's sniff (there is no domain to match before it).
  #
  # QUIC is refused ahead of the bridge rule (see `core.reject`): the bridge is
  # `ssh -D`, which has no SOCKS5 UDP ASSOCIATE, so HTTP/3 to a corp FakeIP
  # would otherwise go to the bridge and hang until the browser gives up on it.
  routeRules = [
    (core.reject (core.quic // { domain_suffix = domains; }))
    {
      domain_suffix = domains;
      outbound = socksBridge.tag;
    }
  ];
}
