{ config, lib, ... }:
{
  programs.ssh = lib.mkIf config.me.isMainMachine {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      vps-lima = {
        hostname = "127.0.0.1";
        user = "root";
        port = 53555;
      };
    };
  };
}
