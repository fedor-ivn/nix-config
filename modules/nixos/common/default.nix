{ config, pkgs, lib, flake, ... }:
{
  imports = [
    ./my-users.nix
  ];

  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    fallbackDns = [
      "8.8.8.8"
      "8.8.4.4"
      "1.1.1.1"
      "1.0.0.1"
    ];
  };


  services.tailscale.enable = true;

  # services.earlyoom = {
  #   enable = true;
  #   freeSwapThreshold = 20;
  #   reportInterval = 0;
  #   enableNotifications = true;
  #   extraArgs = [ "--avoid plasmashell" ];
  # };

  # Common firewall tweaks (e.g., for Tailscale/WireGuard UDP port 51830)
  networking.firewall = {
    logReversePathDrops = true;
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51830 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51830 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51830 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51830 -j RETURN || true
    '';
  };

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  programs.ssh.startAgent = true;
  services.fwupd.enable = true;

  nix = {
    gc.automatic = true;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
