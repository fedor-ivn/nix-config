# The pieces every sing-box profile is built from, in groups along two
# independent axes:
#
#   ./core.nix    what any tun profile needs
#   ./tunnel.nix  egress through the subscription (`route.final = "proxy"`)
#   ./corp.nix    corp domains over the reverse-SSH SOCKS bridge
#
# Profiles (../profiles/) assemble these into a whole config themselves rather
# than filling hooks in a shared skeleton: `dns.rules` and `route.rules` are
# ordered match-lists, and spelling them out at the call site is what makes a
# profile's routing readable. A group is the unit of reuse — its rules keep their
# order inside it — and the order *between* groups is the same everywhere:
#
#   core.prelude ++ corp.routeRules ++ tunnel.routeRules
#                   corp.dnsRules   ++ tunnel.dnsRules
#
# A single rule or helper moves into ./core.nix only once a second group needs
# it (`reject`, `quic`).
{ lib, platform }:
let
  core = import ./core.nix { inherit lib platform; };
in
{
  inherit core;
  tunnel = import ./tunnel.nix { inherit core; };
  corp = import ./corp.nix { inherit core; };
}
