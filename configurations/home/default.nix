# Generic home-manager config, shared by every managed account. The account
# username is injected per host (see modules/nixos/common/users.nix); the
# identity (name/email/SSH key) is the same person everywhere.
{ flake, config, osConfig ? { }, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  identity = import ../../lib/identity.nix;
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

  # `me.username` is set per account in users.nix.
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
