{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    # Ported from old nix-darwin config.
    theme = "miasma";
    settings = {
      colors = {
        normal.black = "#565C63";
        primary.background = "#252525";
      };
      cursor = {
        blink_interval = 500;
        blink_timeout = 0;
        thickness = 0.25;
        style = {
          blinking = "Always";
          shape = "Beam";
        };
      };
      window = {
        dynamic_padding = true;
        opacity = 0.95;
        blur = true;
        dimensions = {
          columns = 140;
          lines = 42;
        };
        decorations = "Full";
        padding = {
          x = 8;
          y = 8;
        };
        option_as_alt = "Both";
      };
      terminal.shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = [ "-l" ];
      };
      keyboard.bindings = [
        {
          action = "ToggleViMode";
          key = "Space";
          mods = "Command|Shift";
        }
      ];
    };
  };
}
