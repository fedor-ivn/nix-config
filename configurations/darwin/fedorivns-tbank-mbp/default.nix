{ flake, pkgs, ... }:
let
  secrets = flake.inputs.secrets.values;
in
{
  imports = [ flake.inputs.self.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 5;

  system.primaryUser = "ext.fivanov";

  networking.hostName = "fedorivns-tbank-mbp";
  networking.localHostName = "fedorivns-tbank-mbp";
  networking.computerName = "fedorivns-tbank-mbp";
}
