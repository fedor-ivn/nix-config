{ flake, ... }:
let
  secrets = flake.inputs.secrets.values;
in
{
  imports = [ flake.inputs.self.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 5;

  # TODO: make it DRY with substitutions
  system.primaryUser = "fedorivn";

  networking.hostName = "fedorivns-mbp";
  networking.computerName = "fedorivns-mbp";
  networking.knownNetworkServices = [
    "USB Controls 2"
    "USB Controls"
    "USB 10/100/1000 LAN"
    "Thunderbolt Bridge"
    "Wi-Fi"
    "iPhone USB"
  ] ++ secrets.knownNetworkServices;

  networking.dns = [
    "8.8.8.8"
    "8.8.4.4"
    "1.1.1.1"
    "1.0.0.1"
    "2001:4860:4860::8888"
    "2001:4860:4860::8844"
  ];
}
