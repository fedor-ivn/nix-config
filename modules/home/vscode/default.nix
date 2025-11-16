{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = import ./settings.nix;
      extensions = import ./extensions.nix pkgs;
      keybindings = import ./keybindings.nix;
    };
  };
}
