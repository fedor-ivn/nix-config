## Why

The ThinkPad needs disk space freed to accommodate a second NixOS installation (homelab server, see `add-fedorivns-homelab` change) via dual boot. Currently 107G of 218G is consumed by the Nix store alone, driven by accumulated system generations and heavy GUI packages deployed to all Linux hosts. Manual one-time cleanup handles the acute situation; structural config changes prevent recurrence and ensure the desktop and server partitions can coexist.

## What Changes

- **Manual (already done / to do once):**
  - Old nix system generations deleted ✓
  - Remove Rust `target/`, Elixir `_build/`, Poetry/Mix caches from inactive projects
  - Clear `~/.cache/{pypoetry,mix,pyright-python,evision-nif*,mozilla,thumbnails}`

- **Config restructuring:**
  - Extract a `thinkpadOnly` package list in `modules/home/packages.nix` to stop delivering heavy GUI apps (Slack, LibreOffice, Zoom, Chromium, qBittorrent, Hoppscotch) to the ThinkPad
  - Remove `hoppscotch` from the `base` list entirely — `posting` already covers HTTP testing
  - Enable automatic NixOS-level GC (`nix.gc`) on the ThinkPad system config to keep old generations pruned automatically

## Capabilities

### New Capabilities

- `thinkpad-package-optimization`: Host-specific package selection that limits the ThinkPad to lightweight/essential packages, moving heavy GUI apps out of the shared `base`/`linuxOnly` lists into a separate block only included on machines where they're wanted.

### Modified Capabilities

<!-- No existing specs change behavioral requirements -->

## Impact

- `modules/home/packages.nix`: add `thinkpadOnly` package list, remove `hoppscotch` from `base`
- `configurations/nixos/fedorivns-thinkpad/default.nix`: enable `nix.gc` with `--delete-older-than 7d`
- One-time shell commands for cache/build-artifact cleanup (documented in tasks)
