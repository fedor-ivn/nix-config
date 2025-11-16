{ pkgs, ... }:
{
  programs = {
    # Zsh: merge old nix-darwin settings with new layout.
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      history = {
        append = true;
        share = true;
        ignoreAllDups = true;
        ignoreSpace = true;
      };
      syntaxHighlighting.enable = true;

      # Keep hooks for extra config if needed.
      envExtra = ''
        # Custom ~/.zshenv goes here
      '';
      profileExtra = ''
        # Custom ~/.zprofile goes here
      '';
      loginExtra = ''
        # Custom ~/.zlogin goes here
      '';
      logoutExtra = ''
        # Custom ~/.zlogout goes here
      '';

      # macOS-specific keybindings (option+arrow behaviour)
      initContent = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        # Keybindings from old macOS config
        bindkey "^[[1;3C" forward-word
        bindkey "^[[1;3D" backward-word
      '';
    };

    # Type `z <pat>` to cd to some directory (from old zoxide.nix)
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Better shell prompt!
    starship = {
      enable = true;
      settings = {
        username = {
          style_user = "blue bold";
          style_root = "red bold";
          format = "[$user]($style) ";
          disabled = false;
          show_always = true;
        };
        hostname = {
          ssh_only = false;
          ssh_symbol = "🌐 ";
          format = "on [$hostname](bold red) ";
          trim_at = ".local";
          disabled = false;
        };
      };
    };
  };
}
