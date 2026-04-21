{ config, ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    skills = config.me.ai.skills;
    commands = config.me.ai.commands;
  };
}
