{ pkgs, lib, config, ... }:
{
  options.programs.syncthing.enable = lib.mkEnableOption "Syncthing background agent (launchd)";

  config = lib.mkIf (config.programs.syncthing.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    launchd.agents.syncthing = {
      enable = true;
      config = {
        ProgramArguments = [ "${pkgs.syncthing}/bin/syncthing" ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/syncthing.out.log";
        StandardErrorPath = "/tmp/syncthing.err.log";
      };
    };
  };
}
