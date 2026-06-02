## Context

Ghostty sets `TERM=xterm-ghostty`. Remote machines without Ghostty's terminfo entry fail with `can't find terminal definition for xterm-ghostty`. The fix is layered: auto-copy terminfo on connect (shell integration), pre-install on owned NixOS remotes (system package), and a fallback SSH wrapper alias.

Current state: `modules/home/ghostty.nix` has `programs.ghostty` configured with no settings. `modules/nixos/common/default.nix` is the shared NixOS module applied to all hosts. `modules/home/shell.nix` owns `home.shellAliases`.

## Goals / Non-Goals

**Goals:**
- SSH from Ghostty into any target (NixOS or not) without terminfo errors
- All config lives in home-manager / NixOS modules — no per-host manual steps
- Works for both `fedorivns-thinkpad` (current) and future NixOS hosts automatically

**Non-Goals:**
- Fixing third-party servers not in this flake (covered by shell integration auto-copy)
- Supporting non-zsh shells (only zsh is configured)

## Decisions

### 1. `shell-integration-features = "ssh-env,ssh-terminfo"` in ghostty HM settings

Added to `modules/home/ghostty.nix` under `programs.ghostty.settings`. This hooks into Ghostty's shell integration and auto-runs `infocmp | tic` on first connect to any host. Covers arbitrary non-NixOS targets.

Alternative: `term = "xterm-256color"` — degrades terminal capabilities (no true color, etc). Rejected.

### 2. `pkgs.ghostty.terminfo` in NixOS system packages

Added to `modules/nixos/common/default.nix` so all current and future NixOS hosts in the flake get it. `ghostty.terminfo` is a split output — no Ghostty binary on the server, just the terminfo database entry. Clean, composable.

Alternative: `environment.enableAllTerminfo = true` — installs terminfo for all terminals (kitty, wezterm, etc.). Overkill for one terminal. Rejected.

### 3. `ssh = "ghostty +ssh"` shell alias

Added to `home.shellAliases` in `modules/home/shell.nix`. `ghostty +ssh` is a drop-in wrapper that installs terminfo on first connect and forwards args verbatim. Fallback for cases where shell integration (Decision 1) fails (e.g., restricted hosts per Discussion #9708).

`ghostty` binary is available on both Darwin (Homebrew) and Linux (pkgs.ghostty via HM), so the alias is safe unconditionally.

## Risks / Trade-offs

- `shell-integration-features` requires Ghostty shell integration active in zsh — already enabled by default with `programs.ghostty.enableZshIntegration = true` (HM default) → no issue
- `ghostty +ssh` alias shadows system `ssh` — harmless since it exec's the real `ssh` binary with args forwarded verbatim; `\ssh` bypasses alias if needed
- `ghostty.terminfo` split output availability: confirmed present in nixpkgs (ghostty package has `.terminfo` output)
