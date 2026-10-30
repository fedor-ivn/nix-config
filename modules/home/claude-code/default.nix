{ config, pkgs, flake, ... }:
let
  rtk-hook = pkgs.callPackage ./rtk-hook.nix { };

  # opus-5-5 is also available on the proxy, but needs Claude Code >= 2.1.280.
  pclaudeModel = "anthropic/claude-opus-5";
  pclaudeSmallModel = "anthropic/claude-haiku-4-5-20251001";

  pclaudeSettings = pkgs.writeText "pclaude-settings.json" (builtins.toJSON {
    model = pclaudeModel;
    # llm-proxy security guardrail rejects the whole request with 403
    # ("Malicious MCP detected. Invalid tools: ...") if any of these servers'
    # tools are present; a server-level deny strips them from the request.
    # time/whiteboard are flagged for their OAuth `authenticate` stub tools.
    permissions.deny = map (s: "mcp__plugin_hm_${s}") [
      "context7"
      "playwright"
      "time"
      "whiteboard"
    ];
    # claude.ai connectors can't load with a custom auth token anyway; opting
    # out explicitly silences the "connectors are disabled" startup warning.
    disableClaudeAiConnectors = true;
  });

  pclaude = pkgs.writeShellApplication {
    name = "pclaude";
    text = ''
      ANTHROPIC_BASE_URL=$(cat ${config.sops.secrets."pclaude/anthropic-base-url".path}) \
      ANTHROPIC_AUTH_TOKEN=$(cat ${config.sops.secrets."pclaude/anthropic-auth-token".path}) \
      ANTHROPIC_CUSTOM_MODEL_OPTION=${pclaudeModel} \
      ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="Claude Opus 5 (llm-proxy)" \
      ANTHROPIC_DEFAULT_HAIKU_MODEL=${pclaudeSmallModel} \
      exec claude --settings ${pclaudeSettings} "$@"
    '';
  };
in
{
  sops.secrets."pclaude/anthropic-auth-token" = { };
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
      remoteControlAtStartup = false;
      agentPushNotifEnabled = false;
      attribution = {
        commit = "";
        sessionUrl = false;
      };
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
