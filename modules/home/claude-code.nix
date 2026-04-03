{ pkgs, lib, flake, ... }:
let
  pkgs-stable = import flake.inputs.nixpkgs-stable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };

  notion-plugin = pkgs.fetchFromGitHub {
    owner = "makenotion";
    repo = "claude-code-notion-plugin";
    rev = "main";
    hash = "sha256-/x5GXCKEwYSs2Wk5mGfKsR4oRdNjGDyYoGitEiX5oPw=";
  };

  gws-skills = pkgs.runCommand "gws-skills" { } ''
    mkdir -p $out/skills
    for skill in \
      gws-shared \
      gws-drive \
      gws-drive-upload \
      gws-gmail \
      gws-gmail-send \
      gws-gmail-triage \
      gws-gmail-reply \
      gws-gmail-reply-all \
      gws-gmail-forward \
      gws-gmail-read \
      gws-gmail-watch; do
      ln -s ${flake.inputs.gws}/skills/$skill $out/skills/$skill
    done
  '';

  skillSources = [ notion-plugin gws-skills ./agents ];

  mergeSkillSources = subdir:
    pkgs.runCommand "claude-${subdir}" { } ''
      mkdir -p $out
      for p in ${lib.concatMapStringsSep " " (p: "${p}") skillSources}; do
        if [ -d "$p/${subdir}" ]; then
          for f in "$p/${subdir}"/*; do
            ln -s "$f" "$out/$(basename "$f")"
          done
        fi
      done
    '';
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs-stable.claude-code;

    mcpServers.notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };

    commandsDir = mergeSkillSources "commands";
    skillsDir = mergeSkillSources "skills";
  };
}
