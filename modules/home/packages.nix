{ pkgs, lib, ... }:
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
        # Unix tools
        ripgrep # Better `grep`
        fd
        sd
        tree
        dig

        # Nix dev
        cachix
        nil # Nix language server
        nix-info
        nixpkgs-fmt

        # On ubuntu, we need this less for `man home-configuration.nix`'s pager to
        # work.
        less

        sops

        # Cross-platform GUI / CLI apps (Linux via Nix; macOS via Homebrew where noted)
        slack
        qbittorrent
        obsidian
        jetbrains-mono
        hoppscotch
        # postman
        zoom-us

        tealdeer
        python313
        gh
        dust
      ];

      linuxOnly = with pkgs; [
        wl-clipboard-rs
        libreoffice
        vlc
        google-chrome
        telegram-desktop
        # beekeeper-studio
      ];

      darwinOnly = with pkgs; [
        alt-tab-macos
        raycast
        monitorcontrol
        stats
        syncthing
        podman
        podman-compose
      ];
    in
    base
    ++ optionals (pkgs.stdenv.hostPlatform.isLinux) linuxOnly
    ++ optionals (pkgs.stdenv.hostPlatform.isDarwin) darwinOnly;

  # Programs natively supported by home-manager.
  # They can be configured in `programs.*` instead of using home.packages.
  programs = {
    # Better `cat` (from old bat.nix)
    bat.enable = true;

    # Fuzzy finder (from old fzf.nix)
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    jq.enable = true;

    firefox = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
    };

    keepassxc = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
    };
  };
}
