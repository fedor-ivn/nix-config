## Why

SSH into remote machines from Ghostty fails with `can't find terminal definition for xterm-ghostty` because the remote lacks Ghostty's terminfo entry. This affects all SSH targets (NixOS remotes, arbitrary servers) and requires a robust, layered fix that lives in home-manager config.

## What Changes

- Add `shell-integration-features = "ssh-env,ssh-terminfo"` to Ghostty's home-manager settings to auto-copy terminfo on connect (covers non-NixOS remotes)
- Add `pkgs.ghostty.terminfo` to NixOS system packages on all managed NixOS hosts (clean server-side fix for owned machines)
- Wire an `ssh = "ghostty +ssh"` shell alias in home-manager as a fallback wrapper

## Capabilities

### New Capabilities
- `ghostty-ssh-terminfo`: Ghostty terminfo propagation for SSH sessions — client-side HM config (ghostty settings + shell alias) and server-side NixOS system package

### Modified Capabilities
<!-- none -->

## Impact

- `configurations/home/fedorivn.nix` or ghostty HM module — add `shell-integration-features`
- All NixOS host configs (currently `fedorivns-thinkpad`) — add `ghostty.terminfo` to system packages
- Shell config (zsh/fish via HM) — add `ssh = "ghostty +ssh"` alias
