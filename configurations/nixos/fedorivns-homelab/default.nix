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
      ${pkgs.gnused}/bin/sed -i '/^default /c\default @saved' /boot/loader/loader.conf
    '';
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  security.sudo.extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";

  system.stateVersion = "26.05";
}
