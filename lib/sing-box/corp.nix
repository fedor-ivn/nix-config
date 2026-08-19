# Corp profile: the base config (./default.nix) with corp-specific surgery on top.
#
# Everything corp-specific lives here so the base profile stays free of it: the
# corp domain list, the FakeIP DNS server that keeps those domains off the
# tunnel's resolver, and the SOCKS outbound that carries them over the
# reverse-SSH bridge (127.0.0.1:1080). Only hosts that actually run that bridge
# use this generator.
#
# Takes exactly the same arguments as the base generator and returns the same
# shape, so the two are interchangeable at the call site.
#
# sing-box evaluates `dns.rules` and `route.rules` top-down, so the patches below
# are positional rather than plain merges: the corp rules have to be matched
# *before* the base's direct rules, or corp traffic falls through to the
# RU/private checks and then to the tunnel, skipping the bridge.
args:
let
  base = import ./default.nix args;

  domains = [
    "tcsbank.ru"
    "t-tech.team"
    "tcsgroup.io"
    "tbank.ru"
    "tinkoff.ru"
  ];

  # Insert `item` ahead of the first element matching `pred`; fails the build if
  # there is none, so a reshuffle of the base rules can't silently drop it.
  insertBeforeFirst = pred: item: list:
    let
      spliced = builtins.foldl'
        (acc: x:
          if acc.done || !(pred x)
          then acc // { out = acc.out ++ [ x ]; }
          else { done = true; out = acc.out ++ [ item x ]; })
        { done = false; out = [ ]; }
        list;
    in
    assert spliced.done; spliced.out;
in
base // {
  dns = base.dns // {
    servers = base.dns.servers ++ [
      {
        tag = "fakeip-dns";
        type = "fakeip";
        inet4_range = "198.18.0.0/15";
        inet6_range = "fc00::/18";
      }
    ];

    rules = [
      # Browsers query the HTTPS/SVCB RR (type 65/64) over the system resolver.
      # The FakeIP server only synthesizes A/AAAA, so these queries get
      # black-holed and Firefox stalls until the fetch dies
      # (NS_ERROR_NET_TIMEOUT, surfaced on the page as a failed CORS request).
      # Forwarding them upstream instead would leak real ipv4hint/ipv6hint + ECH
      # config, letting the client bypass FakeIP and connect with an encrypted
      # SNI we can't sniff — either way the corp domain_suffix route rule never
      # fires and the request skips the SOCKS bridge. Reject them with a fast
      # empty answer so the client falls back to the A/AAAA FakeIP path that
      # routes correctly.
      {
        query_type = [ 64 65 ];
        domain_suffix = domains;
        action = "reject";
      }
      {
        domain_suffix = domains;
        server = "fakeip-dns";
      }
    ] ++ base.dns.rules;
  };

  outbounds = base.outbounds ++ [
    {
      type = "socks";
      tag = "socks-tbank";
      server = "127.0.0.1";
      server_port = 1080;
      version = "5";
    }
  ];

  route = base.route // {
    # After the base's `sniff` / `hijack-dns` actions, ahead of its direct rules.
    rules = insertBeforeFirst (rule: rule ? outbound)
      {
        domain_suffix = domains;
        outbound = "socks-tbank";
      }
      base.route.rules;
  };
}
