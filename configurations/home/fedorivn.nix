{ flake, config, pkgs, inputs, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.homeModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];

  me = {
    username = "fedorivn";
    fullname = "Fedor Ivanov";
    email = "ivnfedor@gmail.com";
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  # Use same state version as system unless you want to bump independently
  home.stateVersion = "23.11";

  # Extra user packages on top of modules/home/packages.nix
  # home.packages = with pkgs; [ htop neovim tmux ];
}
