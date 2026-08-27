{ ... }:
# Terminal multiplexers. Both are enabled on purpose: Ghostty on macOS has no
# non-native tab mode (`window-show-tab-bar` is GTK-only), and macOS native
# tabs are separate NSWindows, so Aerospace sees each tab as its own window
# and tiles an invisible one. Tabs therefore have to live *below* the window
# boundary. tmux is the known quantity for SSH into the ThinkPad/server;
# zellij is on trial for local work.
{
  programs.tmux = {
    enable = true;
    # Home Manager's default is `screen`, which caps tmux at 8 colours and no
    # italics — that quietly undoes the ghostty-ssh-terminfo work.
    terminal = "tmux-256color";
    baseIndex = 1; # tabs start at 1, matching the number row
    mouse = true;
    escapeTime = 10;
    historyLimit = 50000;
    keyMode = "vi";
    focusEvents = true;
    extraConfig = ''
      # Ghostty exports TERM=xterm-ghostty; advertise truecolor inward.
      set -ga terminal-features ",xterm-ghostty:RGB"
      # New tabs inherit the pane's cwd rather than $HOME.
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  programs.zellij = {
    enable = true;
    # Shell integration is deliberately left off: it auto-starts a session in
    # every new shell, which would wrap every Ghostty window before zellij has
    # earned it. Run `zellij` by hand while evaluating.
    settings = {
      # Start locked so zellij intercepts nothing. Its default preset grabs
      # Ctrl-t and Ctrl-r, which collide head-on with the fzf zsh integration
      # in packages.nix, plus Ctrl-p/Ctrl-n/Ctrl-s from the shell itself.
      # Locked-first is the declarative equivalent of the "unlock-first
      # (non-colliding)" preset the UI offers.
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 50000;
      show_startup_tips = false;
      # Match tmux: closing the terminal detaches rather than killing panes.
      on_force_close = "detach";
    };
    # Ctrl-g toggles straight into Tab mode instead of Normal, so tabs are two
    # keystrokes like tmux's prefix: Ctrl-g n (new), Ctrl-g 1-9 (goto),
    # Ctrl-g h/l (prev/next), Ctrl-g r (rename), Ctrl-g Tab (last).
    # Ctrl-g again re-locks; Esc drops to Normal for everything else.
    extraConfig = ''
      keybinds {
          locked {
              bind "Ctrl g" { SwitchToMode "Tab"; }
          }
      }
    '';
  };
}
