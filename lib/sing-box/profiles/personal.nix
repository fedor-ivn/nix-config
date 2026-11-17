# Personal split-tunnel profile.
#
# Everything that should stay outside the tunnel (RU-only sites by rule-set,
# private IPs, the tailnet) goes `direct`; everything else leaves through
# `route.final`, which the subscription's `proxy` selector defines. It adds
# nothing of its own to the match-lists — it *is* core plus the tunnel egress —
# so the lists below read as the shortest possible statement of that shape.
#
# Returns an attrset, rendered by ../render.nix. Design notes:
# openspec/specs/split-tunnel-router/.
{ lib
, platform
  # The subscription nodes plus the `proxy-auto` urltest and `proxy` selector
  # built over them, as a marker string that ../render.nix splices in (see there
  # for why the groups are not named here: their tags must stay out of the Nix
  # store).
, proxyOutbounds
}:
let
  inherit (import ../parts { inherit lib platform; }) core tunnel;
in
{
  inherit (core) log experimental;

  dns = tunnel.dns // {
    servers = tunnel.dnsServers ++ [ core.directDns ];
    rules = tunnel.dnsRules;
  };

  inbounds = [ core.tunInbound ];

  # `proxyOutbounds` is spliced in as-is rather than merged; the selector it
  # defines names `direct` from here, and tags resolve across the whole config.
  outbounds = [ core.direct proxyOutbounds ];

  http_clients = tunnel.httpClients;

  route = core.routeBase // tunnel.route // {
    rules = core.prelude ++ tunnel.routeRules;
  };
}
