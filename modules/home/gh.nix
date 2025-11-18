{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-copilot
      pkgs.gh-poi
    ];
  };
}
