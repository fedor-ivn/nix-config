{ config, pkgs, lib, ... }:
# GUI packages. Platform and desktop-ness are separate axes: the whole file is
# desktop-gated, and the platform splits below only pick which desktop apps
# exist for that OS.
lib.mkIf config.me.gui.enable {
  home.packages =
    let
      linuxOnly = with pkgs; [
        wl-clipboard-rs
        telegram-desktop
        # Were "tmp disabled on ThinkPad" back when this list had no real
        # toggle. openspec/specs/thinkpad-package-optimization still expects
        # them on the ThinkPad — re-add here, or per-host, once decided.
        # libreoffice
        # ungoogled-chromium
      ];

      darwinOnly = with pkgs; [
        monitorcontrol
        stats
      ];
    in
    lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxOnly
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin darwinOnly;

  programs.keepassxc.enable = pkgs.stdenv.hostPlatform.isLinux;
}
