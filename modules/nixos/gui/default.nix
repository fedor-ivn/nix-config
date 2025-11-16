{ config, pkgs, ... }:
{
  imports = [
    ./plasma.nix
  ];

  # Enable X11/Wayland display stack; desktop specifics go in plasma.nix
  services.xserver.enable = true;
}
