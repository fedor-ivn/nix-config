{ pkgs, lib, ... }:
let
  notion-plugin = pkgs.fetchFromGitHub {
    owner = "makenotion";
    repo = "claude-code-notion-plugin";
    rev = "main";
    hash = "sha256-/x5GXCKEwYSs2Wk5mGfKsR4oRdNjGDyYoGitEiX5oPw=";
  };
in
{
  programs.claude-code = {
    enable = true;

    mcpServers.notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };

    commandsDir = "${notion-plugin}/commands";
    skillsDir = "${notion-plugin}/skills";
  };
}
