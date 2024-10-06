{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    config = {
      warn_timeout = "0s";
      hide_env_diff = true;
    };
  };
}
