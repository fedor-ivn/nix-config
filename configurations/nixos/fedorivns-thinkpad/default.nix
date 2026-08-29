# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ flake, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    flake.inputs.self.nixosModules.default
    flake.inputs.self.nixosModules.syncthing
  ];

  nixos-unified.sshTarget = "fedorivn@fedorivns-thinkpad.local";
  managedUsers = [ "fedorivn" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Host-specific settings for this machine
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.extraInstallCommands = ''
    for old in /boot/loader/entries/thinkpad-nixos-generation-*.conf; do
      [ -f "$old" ] || continue
      num="''${old##*thinkpad-nixos-generation-}"
      num="''${num%.conf}"
      [ -e "/nix/var/nix/profiles/system-''${num}-link" ] || ${pkgs.coreutils}/bin/rm "$old"
    done
    for f in /boot/loader/entries/nixos-generation-*.conf; do
      [ -f "$f" ] || continue
      if ${pkgs.gnugrep}/bin/grep -q "fedorivns-thinkpad" "$f"; then
        ${pkgs.gnused}/bin/sed -i 's/^title .*/title Thinkpad/' "$f"
        ${pkgs.coreutils}/bin/mv "$f" "/boot/loader/entries/thinkpad-$(${pkgs.coreutils}/bin/basename "$f")"
      fi
    done
    ${pkgs.gnused}/bin/sed -i '/^default /c\default @saved' /boot/loader/loader.conf
  '';
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-12eb18d9-ffeb-4cf7-8afb-1b40347bab6a".device = "/dev/disk/by-uuid/12eb18d9-ffeb-4cf7-8afb-1b40347bab6a";

  networking.hostName = "fedorivns-thinkpad";

  # Documents sync moved to fedorivns-homelab (same physical machine, dual
  # boot); see modules/nixos/syncthing.nix and lib/syncthing.
  syncthing.enable = false;

  home-manager.users.fedorivn.me.gui.enable = true;
  home-manager.users.fedorivn.me.prompt.hostnameColor = "bold bright-red";
  home-manager.users.fedorivn.home.packages = with pkgs; [ vlc ];

  nix.gc.automatic = true;
  system.stateVersion = "23.11";
}
