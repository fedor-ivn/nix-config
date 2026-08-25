{ config, lib, pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.github-copilot-cli
      pkgs.gh-poi
    ];
  };

  # ghcr.io authenticates with the same PAT as `gh`. Only wired up when the
  # Docker config is managed declaratively; sops substitutes the token at
  # activation time.
  sops.secrets."github/pat" =
    lib.mkIf config.programs.dockerConfig.enable { };

  programs.dockerConfig.auths."ghcr.io" =
    lib.mkIf config.programs.dockerConfig.enable {
      username = "fedor-ivn";
      password = config.sops.placeholder."github/pat";
    };
}
