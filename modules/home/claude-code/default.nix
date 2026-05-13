{ config, pkgs, flake, ... }:
let
  rtk-hook = pkgs.callPackage ./rtk-hook.nix { };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    skills = config.me.ai.skills;
    commands = config.me.ai.commands;

    plugins = [
      "${flake.inputs.claude-plugins-official}/plugins/rust-analyzer-lsp"
    ];

    settings = {
      model = "opus";
      effortLevel = "xhigh";
      preferredNotifChannel = "notifications_disabled";
      remoteControlAtStartup = true;
      agentPushNotifEnabled = true;
      hooks.PreToolUse = [{
        matcher = "Bash";
        hooks = [{
          type = "command";
          command = "${rtk-hook}/bin/rtk-rewrite-hook";
        }];
      }];
    };
  };
}
