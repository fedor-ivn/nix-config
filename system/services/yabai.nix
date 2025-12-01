{
  services.yabai = {
    enable = true;
    config = {
      layout = "bsp";
      window_placement = "second_child";
      mouse_follows_focus = "on";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
    };
    extraConfig = ''
      yabai -m mouse_drop_action swap
      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^Calculator$" manage=off
      yabai -m rule --add app="^MonitorControl$" manage=off
      yabai -m rule --add app="^Raycast$" manage=off
    '';
  };
}
