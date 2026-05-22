{ config, pkgs, flake, ... }:
let
  rtk-hook = pkgs.callPackage ./rtk-hook.nix { };
  clamor-hook = pkgs.callPackage ./clamor-hook.nix { inherit flake; };
  clamorHook = {
    type = "command";
    command = "${clamor-hook}/bin/clamor-state-hook";
    timeout = 5;
  };
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
          { hooks = [ clamorHook ]; }
        ];
        PostToolUse = [{ hooks = [ clamorHook ]; }];
        UserPromptSubmit = [{ hooks = [ clamorHook ]; }];
        Notification = [{ hooks = [ clamorHook ]; }];
        PermissionRequest = [{ hooks = [ clamorHook ]; }];
        PreCompact = [{ hooks = [ clamorHook ]; }];
        Stop = [{ hooks = [ clamorHook ]; }];
      };
    };
  };
}
