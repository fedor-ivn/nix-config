{ ... }:
{
  xdg.configFile."clamor/config.yaml".text = ''
    folders:
      obsidian:
        path: ~/obsidian
        backends: [claude-code]
      nix-config:
        path: ~/projects/nix-config
        backends: [claude-code]

    backends:
      claude-code:
        display_name: Claude Code
        spawn:
          cmd: [claude, "{{prompt}}"]
        resume:
          cmd: [claude, --resume, "{{resume_token}}"]
        capabilities:
          resume: true
          sync_output_mode: true
  '';
}
