{ pkgs, lib, flake, ... }:
let
  pkgs-stable = import flake.inputs.nixpkgs-stable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  notion-plugin = pkgs.fetchFromGitHub {
    owner = "makenotion";
    repo = "claude-code-notion-plugin";
    rev = "main";
    hash = "sha256-/x5GXCKEwYSs2Wk5mGfKsR4oRdNjGDyYoGitEiX5oPw=";
  };

  # Skill names to include from each source (null = all)
  gwsSkillNames = [
    "gws-shared"
    "gws-drive"
    "gws-drive-upload"
    "gws-gmail"
    "gws-gmail-send"
    "gws-gmail-triage"
    "gws-gmail-reply"
    "gws-gmail-reply-all"
    "gws-gmail-forward"
    "gws-gmail-read"
    "gws-gmail-watch"
    "gws-calendar"
    "gws-calendar-insert"
    "gws-calendar-agenda"
  ];

  # Skill source definitions
  skillSources = [
    # Notion plugin - all skills/commands
    { src = notion-plugin; }
    # GWS CLI - selective skills only
    { src = flake.inputs.gws; skills = gwsSkillNames; }
    # Agentic Kit (private) - selective skills only
    { src = flake.inputs.agentic-kit; skills = ["crazy"]; }
    # Local agents
    { src = ./agents; }
  ];

  # Generate symlink commands for a single source
  symlinkSource = subdir: source:
    let
      src = source.src;
      selectiveItems = source.${subdir} or null;
    in
    if selectiveItems != null then
      lib.concatMapStringsSep "\n" (item: ''
        ln -sf "${src}/${subdir}/${item}" "$out/${item}"
      '') selectiveItems
    else
      # All: symlink everything in the subdir if it exists
      ''
        if [ -d "${src}/${subdir}" ]; then
          for f in "${src}/${subdir}"/*; do
            ln -sf "$f" "$out/$(basename "$f")"
          done
        fi
      '';

  mergeSkillSources = subdir:
    pkgs.runCommand "claude-${subdir}" { } ''
      mkdir -p $out
      ${lib.concatMapStringsSep "\n" (symlinkSource subdir) skillSources}
    '';
in
{
  programs.claude-code = {
    enable = true;

    mcpServers.notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };

    commandsDir = mergeSkillSources "commands";
    skillsDir = mergeSkillSources "skills";
  };
}
