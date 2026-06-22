{ lib, ... }:
{
  programs.codex = {
    enable = lib.mkDefault true;
  };
}
