{ config, flake, ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    skills = config.me.ai.skills;
    commands = config.me.ai.commands;

    plugins = [
      "${flake.inputs.claude-plugins-official}/plugins/rust-analyzer-lsp"
    ];
  };
}
