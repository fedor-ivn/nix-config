# Corp split-tunnel profile: the personal shape plus a bridge for corp domains.
#
# Corp traffic goes over the reverse-SSH SOCKS bridge (127.0.0.1:1080) instead of
# the subscription, and reaches it by FakeIP: the bridge's far side owns the
# routing, so the domains must be resolved *there*, not locally. Only hosts that
# actually run that bridge use this profile.
#
# Takes the same arguments as ./personal.nix and returns the same shape, so the
# two are interchangeable at the call site.
{ lib, platform, proxyOutbounds }:
let
  parts = import ../parts.nix { inherit lib platform; };

  domains = [
    "tcsbank.ru"
    "t-tech.team"
    "tcsgroup.io"
    "tbank.ru"
    "tinkoff.ru"
  ];

  fakeipDns = {
    tag = "fakeip-dns";
    type = "fakeip";
    inet4_range = "198.18.0.0/15";
    inet6_range = "fc00::/18";
  };

  socksBridge = {
    type = "socks";
    tag = "socks-tbank";
    server = "127.0.0.1";
    server_port = 1080;
    version = "5";
  };
in
{
  inherit (parts) log experimental;

  dns = parts.dnsDefaults // {
    servers = parts.dnsServers ++ [ fakeipDns ];

    # Ahead of the fallthrough: matched later, a corp domain would hit the RU
    # check and resolve through the tunnel's resolver instead of FakeIP.
    rules = [
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
    ] ++ parts.dnsFallthrough;
  };

  inbounds = [ parts.tunInbound ];

  outbounds = [ parts.direct proxyOutbounds socksBridge ];

  http_clients = parts.httpClients;

  route = parts.routeDefaults // {
    # Same ordering constraint as the DNS rules above: after the prelude's sniff
    # (there is no domain to match before it), ahead of the fallthrough (which
    # would send these out the tunnel).
    rules = parts.prelude ++ [
      {
        domain_suffix = domains;
        outbound = socksBridge.tag;
      }
    ] ++ parts.fallthrough;
  };
}
