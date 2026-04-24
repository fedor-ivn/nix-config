{ ... }:

let
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
      map
        (binding: {
          name = "${prefix}${binding.key}";
          value = "${command} ${binding.direction}";
        })
        directions
    );

  workspaces = [
    1
    2
    3
    4
    8
    9
  ];

  mkWorkspaceBindings =
    prefix: command:
    builtins.listToAttrs (
      map
        (n: {
          name = "${prefix}${toString n}";
          value = "${command} ${toString n}";
        })
        workspaces
    );

  floatingApps = [
    "System Settings"
    "Calculator"
    "MonitorControl"
    "Raycast"
    "Activity Monitor"
    "Disk Utility"
  ];

  # Apps auto-assigned to workspaces
  appWorkspaceRules = [
    { app = "Code"; workspace = 1; }
    { app = "Firefox"; workspace = 2; }
    { app = "Obsidian"; workspace = 3; }
    { app = "Finder"; workspace = 4; }
    { app = "Ghostty"; workspace = 8; }
    { app = "Telegram"; workspace = 9; }
    { app = "Slack"; workspace = 9; }
    { app = "Spotify"; workspace = 10; }
    { app = "KeePassXC"; workspace = 10; }
  ];
in
{
  services.aerospace = {
    enable = true;
    settings = {
      automatically-unhide-macos-hidden-apps = true;
      default-root-container-layout = "accordion";
      default-root-container-orientation = "auto";
      accordion-padding = 0;

      # External monitor (top) = main: workspaces 1-4
      # MacBook screen (bottom) = secondary: workspaces 8-10
      workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "3" = "main";
        "4" = "main";
        "8" = "secondary";
        "9" = "secondary";
        "10" = "secondary";
      };

      on-window-detected =
        # Floating rules
        (map
          (app: {
            "if"."app-name-regex-substring" = app;
            run = "layout floating";
          })
          floatingApps)
        ++
        # App-to-workspace assignments
        (map
          (rule: {
            "if"."app-name-regex-substring" = "^${rule.app}$";
            run = "move-node-to-workspace ${toString rule.workspace}";
          })
          appWorkspaceRules);

      mode.main.binding =
        mkDirectionBindings "alt-" "focus"
        // mkDirectionBindings "shift-alt-" "swap"
        // mkDirectionBindings "ctrl-alt-" "move"
        // mkWorkspaceBindings "alt-" "workspace"
        // mkWorkspaceBindings "shift-alt-" "move-node-to-workspace"
        // {
          # Monitor focus (vertical stack: external top, MacBook bottom)
          "alt-s" = "focus-monitor --wrap-around down";
          "alt-d" = "focus-monitor --wrap-around up";
          "shift-alt-s" = "move-node-to-monitor --focus-follows-window down";
          "shift-alt-d" = "move-node-to-monitor --focus-follows-window up";

          # Layout
          "shift-alt-space" = "layout accordion tiles";
          "shift-alt-t" = "layout floating tiling";
          "shift-alt-m" = "fullscreen";
          "alt-e" = "balance-sizes";

          # Move to adjacent workspace
          "shift-alt-p" = "move-node-to-workspace --wrap-around prev";
          "shift-alt-n" = "move-node-to-workspace --wrap-around next";

          # Workspace 10 (alt-0)
          "alt-0" = "workspace 10";
          "shift-alt-0" = "move-node-to-workspace 10";

          # Quick switch to previous workspace
          "alt-tab" = "workspace-back-and-forth";

          # Resize mode
          # "alt-r" = "mode resize";
        };

    #   mode.resize.binding = {
    #     "h" = "resize width -50";
    #     "j" = "resize height +50";
    #     "k" = "resize height -50";
    #     "l" = "resize width +50";
    #     "minus" = "resize smart -50";
    #     "equal" = "resize smart +50";
    #     "esc" = "mode main";
    #   };
    };
  };
}
