{ flake, config, osConfig ? { }, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  identities = import ../../lib/identities.nix;
  identity = identities.fedorivn;
  isMainMachine = osConfig.networking.hostName == "fedorivns-mbp";
in
{
  imports = [
    self.homeModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];

  me = identity // {
    inherit isMainMachine;
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  # Use same state version as system unless you want to bump independently
  home.stateVersion = "24.05";

  # Extra user packages on top of modules/home/packages.nix
  # home.packages = with pkgs; [ htop neovim tmux ];
}
