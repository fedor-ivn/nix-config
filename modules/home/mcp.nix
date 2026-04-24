{ ... }:
{
  programs.mcp = {
    enable = true;
    # servers.notion.url = "https://mcp.notion.com/mcp";
  };

  mcp-servers.programs.playwright.enable = true;
}
