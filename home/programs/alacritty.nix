{
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;
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
      keyboard.bindings = [
        {
          action = "ToggleViMode";
          key = "Space";
          mods = "Command|Shift";
        }
      ];
    };
    # settings = {
    #   bell = {
    #     animation = "Ease";
    #     color = "#1C1C1C";
    #     duration = 400;
    #   };
    #   colors = {
    #     normal.black = "#565C63";
    #     primary.background = "#252525";
    #   };
    #   font = {
    #     size = 10;
    #     glyph_offset = {
    #       x = 0;
    #       y = 2;
    #     };
    #     normal.family = "JetBrains Mono";
    #     offset = {
    #       x = 0;
    #       y = 4;
    #     };
    #   };
    #   mouse.hide_when_typing = true;
    #   shell.program = "tmux";
  };
}
