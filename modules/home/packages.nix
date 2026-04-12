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
        lima
        posting
        flake.inputs.gws.packages.${pkgs.stdenv.system}.default

        # Nix dev
        cachix
        nil # Nix language server
        nix-info
        nixpkgs-fmt

        # Cross-platform GUI / CLI apps (Linux via Nix; macOS via Homebrew where noted)
        slack
        qbittorrent
        jetbrains-mono
        hoppscotch
        zoom-us

        python313
        dust
      ];

      linuxOnly = with pkgs; [
        wl-clipboard-rs
        libreoffice
        vlc
        ungoogled-chromium
        telegram-desktop
      ];

      darwinOnly = with pkgs; [
        alt-tab-macos
        raycast
        monitorcontrol
        stats
        syncthing
        podman
        podman-compose
        docker-client
        iina
        postman
      ];
    in
    base
    ++ optionals (pkgs.stdenv.hostPlatform.isLinux) linuxOnly
    ++ optionals (pkgs.stdenv.hostPlatform.isDarwin) darwinOnly;

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
