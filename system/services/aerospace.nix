{ ... }:

{
  services.aerospace = {
    enable = true;
    settings = {
      after-login-command = [ ];
      after-startup-command = [ ];

      automatically-unhide-macos-hidden-apps = true;

      # Default layout: accordion = stacking (windows fill display, cycle with alt-tab)
      default-root-container-layout = "accordion";
      default-root-container-orientation = "auto";

      # 0 = focused window fills the display fully in accordion/stack mode
      accordion-padding = 0;

      # gaps = {
      #   inner = {
      #     horizontal = 8;
      #     vertical = 8;
      #   };
      #   outer = {
      #     left = 8;
      #     right = 8;
      #     top = 8;
      #     bottom = 8;
      #   };
      # };

      # Equivalent to yabai `rule --add manage=off`
      on-window-detected = [
        {
          "if"."app-name-regex-substring" = "System Settings";
          run = "layout floating";
        }
        {
          "if"."app-name-regex-substring" = "Calculator";
          run = "layout floating";
        }
        {
          "if"."app-name-regex-substring" = "MonitorControl";
          run = "layout floating";
        }
        {
          "if"."app-name-regex-substring" = "Raycast";
          run = "layout floating";
        }
      ];

      mode.main.binding = {
        # ── Window Focus ──────────────────────────────────────────────
        "alt-h" = "focus left";
        "alt-j" = "focus down";
        "alt-k" = "focus up";
        "alt-l" = "focus right";

        # Cycle through windows in current workspace (accordion/stack mode)
        "alt-tab" = "focus dfs-next";
        "shift-alt-tab" = "focus dfs-prev";

        # ── Monitor Focus ─────────────────────────────────────────────
        "alt-s" = "focus-monitor --wrap-around down"; # → laptop (below external)
        "alt-d" = "focus-monitor --wrap-around up"; # → external (above laptop)

        # ── Layout ───────────────────────────────────────────────────
        "shift-alt-space" = "layout accordion tiles"; # toggle stack ↔ tiles
        "shift-alt-t" = "layout floating tiling"; # toggle float
        "shift-alt-m" = "fullscreen"; # maximize
        "alt-e" = "balance-sizes"; # balance window sizes

        # ── Swap Windows ──────────────────────────────────────────────
        "shift-alt-h" = "swap left";
        "shift-alt-j" = "swap down";
        "shift-alt-k" = "swap up";
        "shift-alt-l" = "swap right";

        # ── Move Windows in Tree (was yabai --warp) ───────────────────
        "ctrl-alt-h" = "move left";
        "ctrl-alt-j" = "move down";
        "ctrl-alt-k" = "move up";
        "ctrl-alt-l" = "move right";

        # ── Move Window to Monitor ────────────────────────────────────
        "shift-alt-s" = "move-node-to-monitor --focus-follows-window down";
        "shift-alt-d" = "move-node-to-monitor --focus-follows-window up";

        # ── Workspace Switching ───────────────────────────────────────
        "alt-1" = "workspace 1";
        "alt-2" = "workspace 2";
        "alt-3" = "workspace 3";
        "alt-4" = "workspace 4";
        "alt-5" = "workspace 5";
        "alt-6" = "workspace 6";
        "alt-7" = "workspace 7";
        "alt-8" = "workspace 8";
        "alt-9" = "workspace 9";

        # ── Move Window to Workspace ──────────────────────────────────
        "shift-alt-1" = "move-node-to-workspace 1";
        "shift-alt-2" = "move-node-to-workspace 2";
        "shift-alt-3" = "move-node-to-workspace 3";
        "shift-alt-4" = "move-node-to-workspace 4";
        "shift-alt-5" = "move-node-to-workspace 5";
        "shift-alt-6" = "move-node-to-workspace 6";
        "shift-alt-7" = "move-node-to-workspace 7";
        "shift-alt-8" = "move-node-to-workspace 8";
        "shift-alt-9" = "move-node-to-workspace 9";

        "shift-alt-p" = "move-node-to-workspace --wrap-around prev";
        "shift-alt-n" = "move-node-to-workspace --wrap-around next";
      };
    };
  };
}
