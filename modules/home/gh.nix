{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.github-copilot-cli
      pkgs.gh-poi
    ];
  };
}
