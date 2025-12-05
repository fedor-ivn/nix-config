{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    history = {
      append = true;
      share = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };
    syntaxHighlighting.enable = true;
    envExtra = ''
      # Point Docker CLI to Podman's socket
      export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
    '';
    initContent = ''
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
    '';
  };
}
