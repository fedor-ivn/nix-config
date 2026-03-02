{ flake, ... }:
let
  identities = import ../../../lib/identities.nix;
in
{
  imports = [
    flake.inputs.disko.nixosModules.disko
  ];

  networking.hostName = "fedorivns-vps";
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    identities.fedorivn.sshPublicKey
  ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "2G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  system.stateVersion = "24.05";
}
