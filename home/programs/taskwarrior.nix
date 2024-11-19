{ pkgs, ... }:
{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      uda.syncallduration.type="duration";
      uda.syncallduration.label="Duration";
    };
  };
}
