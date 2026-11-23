# Corp split-tunnel profile: the personal shape plus the corp bridge
# (../parts/corp.nix). Only hosts that run the `ssh -D` the bridge points at
# use this profile.
#
# Takes the same arguments as ./personal.nix and returns the same shape, so the
# two are interchangeable at the call site; `bridge` is the only addition and
# `personal` ignores it.
{ lib, platform, proxyOutbounds }:
let
  inherit (import ../parts { inherit lib platform; }) core tunnel corp;
in
{
  inherit (core) log experimental;

  dns = tunnel.dns // {
    servers = tunnel.dnsServers ++ [ core.directDns ] ++ corp.dnsServers;
    rules = corp.dnsRules ++ tunnel.dnsRules;
  };

  inbounds = [ core.tunInbound ];

  outbounds = [ core.direct proxyOutbounds corp.socksBridge ];

  http_clients = tunnel.httpClients;

  route = core.routeBase // tunnel.route // {
    rules = core.prelude ++ corp.routeRules ++ tunnel.routeRules;
  };
}
