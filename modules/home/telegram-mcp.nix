{ config, pkgs, lib, flake, ... }:
let
  telegramMcpPackage = flake.self.packages.${pkgs.stdenv.hostPlatform.system}.telegram-mcp;
in
{
  config = lib.mkIf config.me.isMainMachine {
    sops.secrets = {
      "telegram/api-id" = { };
      "telegram/api-hash" = { };
      "telegram/session-string" = { };
    };

    sops.templates."telegram-mcp.env".content = ''
      TELEGRAM_API_ID=${config.sops.placeholder."telegram/api-id"}
      TELEGRAM_API_HASH=${config.sops.placeholder."telegram/api-hash"}
      TELEGRAM_SESSION_STRING=${config.sops.placeholder."telegram/session-string"}
    '';

    programs.claude-code.mcpServers.telegram = {
      command = lib.getExe (pkgs.writeShellApplication {
        name = "telegram-mcp";
        excludeShellChecks = [ "SC1091" ];
        text = ''
          set -a; source ${config.sops.templates."telegram-mcp.env".path}; set +a
          exec ${lib.getExe' telegramMcpPackage "telegram-mcp"} "$@"
        '';
      });
    };
  };
}
