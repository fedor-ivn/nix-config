{ pkgs, lib, ... }:
{
  programs.ghostty = {
    enable = true;
    # On Darwin, Ghostty is installed via Homebrew cask (no nixpkgs support).
    # Use a dummy package so Home Manager still manages the config.
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;
    settings = {
      shell-integration-features = "ssh-env,ssh-terminfo";
    };
    # Migrated from Alacritty — try defaults first, uncomment to restore.
    # settings = {
    #   theme = "miasma";
    #   background = "252525";
    #   palette = [ "0=#565C63" ];
    #   cursor-style = "bar";
    #   cursor-style-blink = true;
    #   background-opacity = 0.95;
    #   background-blur-radius = 20;
    #   window-padding-x = 8;
    #   window-padding-y = 8;
    #   macos-option-as-alt = true;
    #   command = "${pkgs.zsh}/bin/zsh -l";
    # };
  };
}
