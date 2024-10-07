{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    userSettings = import ./vscode/settings.nix;
    extensions = import ./vscode/extensions.nix pkgs;
  };
}
