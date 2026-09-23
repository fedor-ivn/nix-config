{ config, pkgs, flake, ... }:
let
  rtk-hook = pkgs.callPackage ./rtk-hook.nix { };

  pclaudeSettings = pkgs.writeText "pclaude-settings.json" (builtins.toJSON {
    model = "anthropic/claude-opus-5";
  });

  pclaude = pkgs.writeShellApplication {
    name = "pclaude";
    text = ''
      ANTHROPIC_BASE_URL=$(cat ${config.sops.secrets."pclaude/anthropic-base-url".path}) \
      ANTHROPIC_API_KEY=$(cat ${config.sops.secrets."pclaude/anthropic-api-key".path}) \
      ANTHROPIC_CUSTOM_MODEL_OPTION=anthropic/claude-opus-5 \
      ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="Claude Opus 5 (OpenRouter)" \
      exec claude --settings ${pclaudeSettings} "$@"
    '';
  };
in
{
  sops.secrets."pclaude/anthropic-api-key" = { };
  sops.secrets."pclaude/anthropic-base-url" = { };

  home.packages = [ pclaude ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    skills = config.me.ai.skills;
    commands = config.me.ai.commands;

    plugins = {
      rust-analyzer-lsp = "${flake.inputs.claude-plugins-official}/plugins/rust-analyzer-lsp";
    };

    settings = {
      model = "opus";
      preferredNotifChannel = "notifications_disabled";
      remoteControlAtStartup = true;
      agentPushNotifEnabled = true;
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [{
              type = "command";
              command = "${rtk-hook}/bin/rtk-rewrite-hook";
            }];
          }
        ];
      };
    };
  };
}
