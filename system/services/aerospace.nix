{ ... }:

let
  # h/j/k/l → left/down/up/right
  directions = [
    {
      key = "h";
      direction = "left";
    }
    {
      key = "j";
      direction = "down";
    }
    {
      key = "k";
      direction = "up";
    }
    {
      key = "l";
      direction = "right";
    }
  ];

  mkDirectionBindings =
    prefix: command:
    builtins.listToAttrs (
      map (binding: {
        name = "${prefix}${binding.key}";
        value = "${command} ${binding.direction}";
      }) directions
    );

  # Active workspaces (easy to extend later)
  workspaces = [
    1
    2
  ];

  mkWorkspaceBindings =
    prefix: command:
    builtins.listToAttrs (
      map (n: {
        name = "${prefix}${toString n}";
        value = "${command} ${toString n}";
      }) workspaces
    );

  # Apps that should always float
  floatingApps = [
    "System Settings"
    "Calculator"
    "MonitorControl"
    "Raycast"
  ];
in
{
  services.aerospace = {
    enable = true;
    settings = {
      automatically-unhide-macos-hidden-apps = true;

      # Default layout: accordion = stacking (windows fill display, cycle with alt-tab)
      default-root-container-layout = "accordion";
      default-root-container-orientation = "auto";

      # 0 = focused window fills the display fully in accordion/stack mode
      accordion-padding = 0;

      on-window-detected = map (app: {
        "if"."app-name-regex-substring" = app;
        run = "layout floating";
      }) floatingApps;

      mode.main.binding =
        mkDirectionBindings "alt-" "focus"
        // mkDirectionBindings "shift-alt-" "swap"
        // mkDirectionBindings "ctrl-alt-" "move"
        // mkWorkspaceBindings "alt-" "workspace"
        // mkWorkspaceBindings "shift-alt-" "move-node-to-workspace"
        // {
          # Monitor focus / move
          "alt-s" = "focus-monitor --wrap-around down";
          "alt-d" = "focus-monitor --wrap-around up";
          "shift-alt-s" = "move-node-to-monitor --focus-follows-window down";
          "shift-alt-d" = "move-node-to-monitor --focus-follows-window up";
          # Layout
          "shift-alt-space" = "layout accordion tiles";
          "shift-alt-t" = "layout floating tiling";
          "shift-alt-m" = "fullscreen";
          "alt-e" = "balance-sizes";
          # Move to prev/next workspace
          "shift-alt-p" = "move-node-to-workspace --wrap-around prev";
          "shift-alt-n" = "move-node-to-workspace --wrap-around next";
        };
    };
  };
}
