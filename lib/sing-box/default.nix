# Index for the sing-box config generator. Consumers import this directory and
# take what they need:
#
#   singBox = import ../../lib/sing-box;
#   singBox.render.mkProfile { profile = singBox.profiles.corp; ... }
#
# ./parts/ holds the pieces and the ordering invariants, ./profiles/ assembles
# them into whole configs, ./render.nix splices in the subscription secret and
# schema-checks the result at build time.
{
  parts = import ./parts;
  render = import ./render.nix;

  # Each takes `{ lib, platform, proxyOutbounds }` and returns a config attrset,
  # so the two are interchangeable at the call site.
  profiles = {
    personal = import ./profiles/personal.nix;
    corp = import ./profiles/corp.nix;
  };
}
