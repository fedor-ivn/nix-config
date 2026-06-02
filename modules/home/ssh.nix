{ config, lib, ... }:
{
  programs.ssh = lib.mkIf config.me.isMainMachine {
    enable = true;
    enableDefaultConfig = false;
  };
}
