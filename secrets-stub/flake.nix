{
  description = "Bootstrap stub for nix-secrets — empty defaults, no SSH required";

  outputs = _: {
    values = {
      syncthingDevices = {
        fedorivns-iphone = "";
        fedorivns-mbp = "";
      };
      knownNetworkServices = [];
      clamorPaths = {};
      homebrewCasks = [];
      corpTunnelUser = "";
    };

    # The private flake also exports `homeModules`, and modules/home/secret-tools.nix
    # imports them unconditionally — so the stub has to answer those names too or
    # a bootstrap build dies with `attribute 'homeModules' missing` before it
    # reaches anything host-specific.
    #
    # Declare-only stand-ins: they define the `enable` options the host configs
    # set and configure nothing. A bootstrap machine therefore builds fine and
    # simply comes up without the private tooling, which is the point of the stub.
    homeModules =
      let
        declareOnly =
          name:
          { lib, ... }:
          {
            options.programs.${name}.enable = lib.mkEnableOption "${name} (stubbed — the real module lives in the private nix-secrets)";
          };
      in
      {
        secretTool1 = declareOnly "secretTool1";
        secretTool2 = declareOnly "secretTool2";
        tunnel = declareOnly "tunnel";
        tunnelAgent = declareOnly "tunnelAgent";
      };
  };
}
