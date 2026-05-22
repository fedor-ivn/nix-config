# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ flake, ... }:
let
  secrets = flake.inputs.secrets.values;
in
{
  imports = [
    ./hardware.nix
    flake.inputs.self.nixosModules.default
  ];

  nixos-unified.sshTarget = "fedorivn@192.168.1.19";

  # Host-specific settings for this machine
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-12eb18d9-ffeb-4cf7-8afb-1b40347bab6a".device = "/dev/disk/by-uuid/12eb18d9-ffeb-4cf7-8afb-1b40347bab6a";

  networking.hostName = "fedorivns-thinkpad";

  services.syncthing = {
    enable = true;
    user = "fedorivn";
    dataDir = "/home/fedorivn/Documents";
    configDir = "/home/fedorivn/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "fedorivns-iphone" = {
          id = secrets.syncthingDevices.fedorivns-iphone;
        };

        "fedorivns-mbp" = {
          id = secrets.syncthingDevices.fedorivns-mbp;
        };
      };

      folders = {
        "Documents" = {
          id = "default";
          path = "/home/fedorivn/Documents";
          devices = [
            "fedorivns-iphone"
            "fedorivns-mbp"
          ];
        };

        "iu" = {
          path = "/home/fedorivn/iu";
          devices = [
            "fedorivns-mbp"
          ];
        };

        "projects" = {
          path = "/home/fedorivn/projects";
          devices = [
            "fedorivns-mbp"
          ];
        };

        "obsidian" = {
          path = "/home/fedorivn/obsidian";
          devices = [
            "fedorivns-mbp"
          ];
        };
      };
    };
  };

  system.stateVersion = "23.11";
}
