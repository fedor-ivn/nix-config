{ config, pkgs, lib, ... }:
# Linux-only: mail lives elsewhere on the macOS hosts.
lib.mkIf (config.me.gui.enable && pkgs.stdenv.hostPlatform.isLinux) {
  programs.thunderbird = {
    enable = true;
    profiles.fedorivn = {
      isDefault = true;
    };
  };
}
