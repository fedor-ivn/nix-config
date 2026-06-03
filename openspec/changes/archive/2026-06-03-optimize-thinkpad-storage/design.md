## Context

`modules/home/packages.nix` currently has three lists: `base` (all hosts), `linuxOnly` (all Linux hosts), `darwinOnly` (macOS). The ThinkPad is the only Linux machine, so `linuxOnly` is effectively "thinkpad only" — but the current `linuxOnly` content and the `base` list both include heavy GUI apps (LibreOffice, Chromium, Slack, Zoom, qBittorrent, Hoppscotch) that are either unused or rarely needed on the ThinkPad.

Additionally there is no automatic system-level GC configured on the ThinkPad, so old system generations accumulate indefinitely.

## Goals / Non-Goals

**Goals:**
- Move rarely-used heavy GUI packages out of `base`/`linuxOnly` into a `thinkpadOnly` list so they can be managed per-host
- Remove `hoppscotch` from `base` entirely (`posting` already covers HTTP testing)
- Enable automatic NixOS GC to prevent generation accumulation
- Document one-time manual cleanup steps as tasks (cache dirs, build artifacts)

**Non-Goals:**
- Auditing the MBP package set
- Moving data to an external drive (separate decision for the user)
- Automated project build-artifact cleanup

## Decisions

### 1. `thinkpadOnly` list in `packages.nix` vs host override in `default.nix`

**Decision**: Add a `thinkpadOnly` list in `modules/home/packages.nix`, guarded by `!config.me.isMainMachine`.

**Rationale**: `isMainMachine` is `true` only on `fedorivns-mbp`, so `!isMainMachine` on Linux = ThinkPad. Keeps package decisions co-located in `packages.nix`. A dedicated `thinkpadOnly` variable name makes intent explicit and is easy to extend if a second Linux host is ever added (at which point it can be split further).

**Alternative considered**: Put extra packages directly in `configurations/nixos/fedorivns-thinkpad/default.nix`. Rejected — mixing system config with HM package lists is awkward and fragments the package inventory.

### 2. Which packages move to `thinkpadOnly`

Heavy GUI apps that live in `base` or `linuxOnly` and are not needed on macOS anyway:
- `slack` → `thinkpadOnly` (macOS uses Homebrew cask)
- `zoom-us` → `thinkpadOnly` (macOS uses Homebrew cask)
- `qbittorrent` → `thinkpadOnly` (macOS uses Homebrew cask)
- `libreoffice` → `thinkpadOnly` (macOS has native alternatives)
- `ungoogled-chromium` → `thinkpadOnly` (macOS uses Homebrew cask)
- `hoppscotch` → **removed entirely** (`posting` covers the use case on all platforms)

`vlc`, `telegram-desktop`, `wl-clipboard-rs` stay in `linuxOnly` — small/needed.

### 3. Automatic GC placement

**Decision**: Enable `nix.gc` in the system NixOS config for the ThinkPad (not HM), using `--delete-older-than 7d`. System-level GC covers both system and user profiles, which HM-level GC does not.

`gc.nix` in HM already sets `nix.gc.automatic = true` but without `options` → it uses the default (`--delete-old`). The system-level config will set `options = "--delete-older-than 7d"` to keep recent rollback capability while preventing indefinite accumulation.

## Risks / Trade-offs

- **Removing packages from `base`**: Apps like Slack/Zoom will no longer be available on macOS via Nix. They need to be covered by the Darwin Homebrew cask list (they likely already are). → Verify before deploying.
- **`!isMainMachine` as ThinkPad proxy**: Will silently apply to any future second Linux host. → Acceptable for now; add a proper `me.host` option if a second Linux host is added.
- **7-day GC window**: Loses rollback older than 7 days. → Acceptable; a `just activate` rebuild is fast enough.
