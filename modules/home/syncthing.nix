{ pkgs, lib, ... }:
{
  launchd.agents.syncthing = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.syncthing}/bin/syncthing" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/syncthing.out.log";
      StandardErrorPath = "/tmp/syncthing.err.log";
    };
  };
}
