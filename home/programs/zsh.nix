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
    initExtra = ''
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
    '';
  };
}
