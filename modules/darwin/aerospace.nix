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

  # Like mkDirectionBindings, but drops back to main mode after acting, so a
  # mode key behaves like a one-shot chord instead of trapping you.
  mkOneShotDirectionBindings = prefix: command:
    builtins.listToAttrs (
      map (b: {
        name = "${prefix}${b.key}";
        value = [ "${command} ${b.direction}" "mode main" ];
      }) directions
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
    { app = "Calendar";    workspace = 7; }
    { app = "Mail";        workspace = 7; }
    { app = "Ghostty";     workspace = 8; }
    { app = "Telegram";    workspace = 9; }
    { app = "Slack";       workspace = 9; }
    { app = "Time";        workspace = 9; }
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

      # Every layer sits on hjkl:
      #   alt-        focus a window inside the current workspace
      #   shift-alt-  swap windows in place
      #   cmd-alt-    navigate — h/l walk the workspace strip, j/k walk the
      #               vertically stacked monitors
      # Carrying a window across workspaces/monitors is `move` mode (alt-s)
      # rather than a fourth chord.
      mode.main.binding =
        mkDirectionBindings "alt-" "focus"
        // mkDirectionBindings "shift-alt-" "swap"
        // mkWorkspaceBindings "alt-" "workspace"
        // mkWorkspaceBindings "shift-alt-" "move-node-to-workspace"
        // {
          # No --wrap-around: these stop at the ends of each axis, so the
          # keypress stays positional instead of cycling forever.
          "cmd-alt-h" = "workspace prev";
          "cmd-alt-l" = "workspace next";
          "cmd-alt-j" = "focus-monitor down";
          "cmd-alt-k" = "focus-monitor up";

          # Two orthogonal toggles: container type, and orientation.
          # `horizontal`/`vertical` keep the current type, `accordion`/`tiles`
          # keep the current orientation.
          "alt-comma"       = "layout accordion tiles";
          "alt-slash"       = "layout horizontal vertical";
          "shift-alt-space" = "layout floating tiling";
          "shift-alt-m"     = "fullscreen";
          "alt-e"           = "balance-sizes";
          "alt-minus"       = "resize smart -50";
          "alt-equal"       = "resize smart +50";

          # Two-digit workspace 10 can't use alt-10
          "alt-0"       = "workspace 10";
          "shift-alt-0" = "move-node-to-workspace 10";

          "alt-tab" = "workspace-back-and-forth";

          "alt-s" = "mode move";
          "alt-r" = "mode resize";
          "shift-alt-semicolon" = "mode service";
        };

      # Same two axes as cmd-alt, but dragging the focused window along.
      mode.move.binding = {
        "h"   = [ "move-node-to-workspace prev" "mode main" ];
        "l"   = [ "move-node-to-workspace next" "mode main" ];
        "j"   = [ "move-node-to-monitor --focus-follows-window down" "mode main" ];
        "k"   = [ "move-node-to-monitor --focus-follows-window up" "mode main" ];
        "esc" = "mode main";
      };

      mode.service.binding =
        mkOneShotDirectionBindings "" "join-with"
        // {
          "esc"       = [ "reload-config" "mode main" ];
          "r"         = [ "flatten-workspace-tree" "mode main" ];
          "f"         = [ "layout floating tiling" "mode main" ];
          "backspace" = [ "close-all-windows-but-current" "mode main" ];

          # Deterministic set, unlike the alt-slash toggle in main
          "t" = [ "layout h_tiles" "mode main" ];
          "v" = [ "layout v_tiles" "mode main" ];
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
