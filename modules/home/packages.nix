{ pkgs, lib, flake, ... }:
let
  inherit (lib) optionals;
in
{
  # Nix packages to install to $HOME
  #
  # Search for packages here: https://search.nixos.org/packages
  #
  # GUI packages live in ./gui/packages.nix, gated on `me.gui.enable`.
  home.packages =
    let
      base = with pkgs; [
        # CLI tools
        glab
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

      darwinOnly = with pkgs; [
        podman
        podman-compose
        docker-client
      ];
    in
    base
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
  };
}
