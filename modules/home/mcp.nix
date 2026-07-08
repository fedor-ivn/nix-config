{ ... }:
{
  programs.mcp = {
    enable = true;
    # servers.notion.url = "https://mcp.notion.com/mcp";
  };

  # https://github.com/natsukium/mcp-servers-nix
  mcp-servers.programs = {
    playwright.enable = true;
    context7.enable = true;
  };
}
