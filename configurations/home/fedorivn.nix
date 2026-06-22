{ flake, config, osConfig ? { }, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  identities = import ../../lib/identities.nix;
  identity = identities.fedorivn;
  isMainMachine =
    osConfig != null
    && (osConfig.networking.hostName or null) == "fedorivns-mbp";
in
{
  imports = [
    self.homeModules.default
    inputs.sops-nix.homeManagerModules.sops
    inputs.mcp-servers-nix.homeManagerModules.default
    inputs.clamor.homeManagerModules.default
  ];

  me = identity // {
    inherit isMainMachine;
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  home.stateVersion = "26.05";
}
