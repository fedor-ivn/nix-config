{ ... }:

let
  directions = [
    { key = "h"; direction = "left"; }
    { key = "j"; direction = "down"; }
    { key = "k"; direction = "up"; }
    { key = "l"; direction = "right"; }
  ];

  mkDirectionBindings = prefix: command:
    builtins.listToAttrs (
      map (b: { name = "${prefix}${b.key}"; value = "${command} ${b.direction}"; }) directions
    );

  mkWorkspaceBindings = prefix: command:
    builtins.listToAttrs (
      map (n: { name = "${prefix}${toString n}"; value = "${command} ${toString n}"; }) workspaces
    );

  aerospaceBin = "/run/current-system/sw/bin/aerospace";

  # External monitor (top) = main: workspaces 1-4
  # MacBook screen (bottom) = secondary: workspaces 8-10
  monitors = [
    { name = "main";      workspaces = [ 1 2 3 4 5 6]; }
    { name = "secondary"; workspaces = [ 7 8 9 10 ]; }
  ];

  monitorGroups = map (m: m.workspaces) monitors;

  # Workspaces with direct alt-N keybindings; workspace 10 → alt-0 handled manually below
  workspaces = builtins.filter (w: w <= 9) (builtins.concatLists monitorGroups);

  workspaceToMonitor = builtins.foldl'
    (acc: m: acc // builtins.listToAttrs (
      map (w: { name = toString w; value = m.name; }) m.workspaces
    ))
    { }
    monitors;

  floatingApps = [
    "System Settings"
    "Calculator"
    "MonitorControl"
    "Raycast"
    "Activity Monitor"
    "Disk Utility"
  ];

  appWorkspaceRules = [
    { app = "Code";        workspace = 1; }
    { app = "Firefox";     workspace = 2; }
    { app = "Obsidian";    workspace = 3; }
    { app = "Finder";      workspace = 4; }
    { app = "Ghostty";     workspace = 8; }
    { app = "Telegram";    workspace = 9; }
    { app = "Slack";       workspace = 9; }
    { app = "Time";        workspace = 9; }
    { app = "Thunderbird"; workspace = 9; }
    { app = "Outlook";     workspace = 9; }
    { app = "Spotify";     workspace = 10; }
    { app = "KeePassXC";   workspace = 10; }
    { app = "Cisco Secure Client";   workspace = 10; }
  ];
in
{
  services.aerospace = {
    enable = true;
    settings = {
      automatically-unhide-macos-hidden-apps = true;
      default-root-container-layout = "accordion";
      default-root-container-orientation = "auto";
      accordion-padding = 30;

      workspace-to-monitor-force-assignment = workspaceToMonitor;

      on-window-detected =
        (map (app: {
          "if"."app-name-regex-substring" = app;
          run = "layout floating";
        }) floatingApps)
        ++
        (map (rule: {
          "if"."app-name-regex-substring" = "^${rule.app}$";
          run = "move-node-to-workspace ${toString rule.workspace}";
        }) appWorkspaceRules);

      mode.main.binding =
        mkDirectionBindings "alt-" "focus"
        // mkDirectionBindings "shift-alt-" "swap"
        // mkDirectionBindings "ctrl-alt-" "move"
        // mkDirectionBindings "alt-shift-cmd-" "join-with"
        // mkWorkspaceBindings "alt-" "workspace"
        // mkWorkspaceBindings "shift-alt-" "move-node-to-workspace"
        // {
          "alt-s" = "focus-monitor --wrap-around down";
          "alt-d" = "focus-monitor --wrap-around up";
          "shift-alt-s" = "move-node-to-monitor --focus-follows-window down";
          "shift-alt-d" = "move-node-to-monitor --focus-follows-window up";

          "alt-shift-cmd-f" = "flatten-workspace-tree";

          "shift-alt-space" = "layout accordion tiles";
          "shift-alt-t"     = "layout floating tiling";
          "shift-alt-m"     = "fullscreen";
          "alt-e"           = "balance-sizes";

          "shift-alt-p" = "move-node-to-workspace --wrap-around prev";
          "shift-alt-n" = "move-node-to-workspace --wrap-around next";

          # Two-digit workspace 10 can't use alt-10
          "alt-0"       = "workspace 10";
          "shift-alt-0" = "move-node-to-workspace 10";

          "alt-tab" = "workspace-back-and-forth";

          "alt-rightSquareBracket" = "workspace next";
          "alt-leftSquareBracket"  = "workspace prev";

          "alt-r" = "mode resize";
        };

      mode.resize.binding = {
        "h"     = "resize width -50";
        "j"     = "resize height +50";
        "k"     = "resize height -50";
        "l"     = "resize width +50";
        "minus" = "resize smart -50";
        "equal" = "resize smart +50";
        "esc"   = "mode main";
      };
    };
  };
}
