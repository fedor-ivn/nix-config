# Personal split-tunnel profile.
#
# Everything that should stay outside the tunnel (RU-only sites by rule-set,
# private IPs, the tailnet) goes `direct`; everything else leaves through
# `route.final`, which the subscription's `proxy` selector defines. It adds
# nothing of its own to the match-lists — it *is* the shared fallthrough — so the
# lists below read as the shortest possible statement of that shape.
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
  parts = import ../parts.nix { inherit lib platform; };
in
{
  inherit (parts) log experimental;

  dns = parts.dnsDefaults // {
    servers = parts.dnsServers;
    rules = parts.dnsFallthrough;
  };

  inbounds = [ parts.tunInbound ];

  # `proxyOutbounds` is spliced in as-is rather than merged; the selector it
  # defines names `direct` from here, and tags resolve across the whole config.
  outbounds = [ parts.direct proxyOutbounds ];

  http_clients = parts.httpClients;

  route = parts.routeDefaults // {
    rules = parts.prelude ++ parts.fallthrough;
  };
}
