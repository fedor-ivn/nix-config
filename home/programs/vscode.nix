{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = import ./vscode/settings.nix;
      extensions = import ./vscode/extensions.nix pkgs;
      keybindings = import ./vscode/keybindings.nix;
    };
  };
}
