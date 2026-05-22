{ pkgs, flake, ... }:
{
  programs.clamor = {
    enable = true;
    package = flake.inputs.clamor.packages.${pkgs.stdenv.hostPlatform.system}.default;

    folders = {
      nix-config = { path = "~/projects/nix-config"; backends = [ "claude-code" ]; };
      clamor     = { path = "~/projects/clamor";     backends = [ "claude-code" ]; };
    };

    backends.claude-code = {
      display_name = "Claude Code";
      spawn = {
        cmd            = [ "direnv" "exec" "{{cwd}}" "claude" "{{prompt}}" ];
        title_template = "{{title}}";
      };
      resume = {
        cmd            = [ "direnv" "exec" "{{cwd}}" "claude" "--resume" "{{resume_token}}" ];
        title_template = "{{title}}";
      };
      capabilities = { resume = true; sync_output_mode = true; };
    };

    dashboard.watch_mode = "fsevents";
  };
}
