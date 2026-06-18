{ pkgs, lib, flake, ... }:
let
  inherit (lib) optionals;
in
{
  # Nix packages to install to $HOME
  #
  # Search for packages here: https://search.nixos.org/packages
  home.packages =
    let
      base = with pkgs; [
        # CLI tools
        tokei
        tree
        dig
        sops
        posting
        ffmpeg
        git-filter-repo
        rtk
        flake.inputs.gws.packages.${pkgs.stdenv.system}.default
        timr-tui

        # Nix dev
        cachix
        nil # Nix language server
        nix-info
        nixpkgs-fmt
        jetbrains-mono

        python313
        dust
      ];

      baseGuiApps = with pkgs; [
        slack
        qbittorrent
        hoppscotch
        zoom-us
      ];

      linuxOnlyGuiApps = with pkgs; [
        wl-clipboard-rs
        # libreoffice # tmp disable on ThinkPad
        vlc
        # ungoogled-chromium # tmp disable on ThinkPad
        telegram-desktop
        hiddify-app
      ];

      darwinOnly = with pkgs; [
        podman
        podman-compose
        docker-client
      ];

      darwinOnlyGuiApps = with pkgs; [
        monitorcontrol
        stats
        iina
      ];
    in
    base
    # tmp disable base gui apps on ThinkPad
    ++ optionals (pkgs.stdenv.hostPlatform.isDarwin) baseGuiApps
    ++ optionals (pkgs.stdenv.hostPlatform.isLinux) linuxOnlyGuiApps
    ++ optionals (pkgs.stdenv.hostPlatform.isDarwin) darwinOnly
    ++ optionals (pkgs.stdenv.hostPlatform.isDarwin) darwinOnlyGuiApps;

  # Programs natively supported by home-manager.
  # They can be configured in `programs.*` instead of using home.packages.
  programs = {
    ripgrep.enable = true;
    bat.enable = true;
    tealdeer.enable = true;
    tmux.enable = true;

    fd = {
      enable = true;
      hidden = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    jq.enable = true;
    yt-dlp.enable = true;
    btop.enable = true;

  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    keepassxc.enable = true;
  };
}
