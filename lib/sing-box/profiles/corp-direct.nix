# Corp-only profile: corp domains over the bridge (../parts/corp.nix), and
# everything else `direct` — no subscription at all.
#
# So none of ../parts/tunnel.nix applies: its direct rules are what
# `route.final = "direct"` already does, its rejects exist because of what the
# subscription nodes cannot carry (HTTP/3 and v6 work fine on the direct path),
# and its `tunnel-dns` names a `proxy` outbound that is not here. Nor are the
# rule-sets it downloads, so there is no `http_clients` either.
#
# Takes the same arguments as ./personal.nix and returns the same shape, so the
# two are interchangeable at the call site; `proxyOutbounds` goes unused, which
# leaves ../render.nix's marker unmatched and the subscription secret unread.
{ lib, platform, proxyOutbounds }:
let
  inherit (import ../parts { inherit lib platform; }) core corp;
in
{
  inherit (core) log experimental;

  dns = {
    final = core.directDns.tag;
    servers = [ core.directDns ] ++ corp.dnsServers;
    rules = corp.dnsRules;
  };

  inbounds = [ core.tunInbound ];

  outbounds = [ core.direct corp.socksBridge ];

  route = core.routeBase // {
    final = core.direct.tag;
    rules = core.prelude ++ corp.routeRules;
  };
}
