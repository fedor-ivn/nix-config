{ flake, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    flake.inputs.self.nixosModules.common
    flake.inputs.self.nixosModules.server
  ];

  nixos-unified.sshTarget = "fedorivn@fedorivns-homelab.local";

  networking.hostName = "fedorivns-homelab";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  boot.loader.systemd-boot = {
    enable = true;
    extraInstallCommands = ''
      for old in /boot/loader/entries/homelab-nixos-generation-*.conf; do
        [ -f "$old" ] || continue
        num="''${old##*homelab-nixos-generation-}"
        num="''${num%.conf}"
        [ -e "/nix/var/nix/profiles/system-''${num}-link" ] || ${pkgs.coreutils}/bin/rm "$old"
      done
      for f in /boot/loader/entries/nixos-generation-*.conf; do
        [ -f "$f" ] || continue
        if ${pkgs.gnugrep}/bin/grep -q "fedorivns-homelab" "$f"; then
          ${pkgs.gnused}/bin/sed -i 's/^title .*/title Homelab/' "$f"
          ${pkgs.coreutils}/bin/mv "$f" "/boot/loader/entries/homelab-$(${pkgs.coreutils}/bin/basename "$f")"
        fi
      done
      ${pkgs.gnused}/bin/sed -i '/^default /c\default @saved' /boot/loader/loader.conf
    '';
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  security.sudo.extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";

  system.stateVersion = "26.05";
}
