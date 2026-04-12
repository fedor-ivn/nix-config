{ pkgs, ... }:
{
  programs = {
    # Zsh: merge old nix-darwin settings with new layout.
    zsh = {
      enable = true;
      autocd = true;
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
      envExtra = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        podman_socket_path="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)"
        if [ -n "$podman_socket_path" ]; then
          export DOCKER_HOST="unix://$podman_socket_path"
        fi
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

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd" "cd" ];
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
