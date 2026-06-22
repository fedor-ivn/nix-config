## Why

The corporate laptop (T-bank) enforces a software allowlist; several packages currently in shared modules are blocked or absent from the registry. Rather than adding option flags everywhere, we move personal-preference packages to host configs (where they belong) and introduce a proper `programs.whisply.enable` option for the one custom module we control.

## What Changes

- `modules/home/packages.nix` — remove `vlc` (linux), `zoom-us` and `iina` (darwin) from shared lists; they move to host configs
- `modules/home/whisply.nix` — introduce `options.programs.whisply.enable` (default `true`); gate module config behind it
- `modules/home/codex.nix` — change `programs.codex.enable = true` to `lib.mkDefault true` so a corp host can override it to `false` without `mkForce`
- `modules/darwin/homebrew.nix` — remove `chatgpt`, `claude`, `altserver` casks; they move to the MBP host config
- `configurations/darwin/fedorivns-mbp/default.nix` — add `iina`, `zoom-us` to `home-manager.users.fedorivn.home.packages`; add `chatgpt`, `claude`, `altserver` to `homebrew.casks`
- `configurations/nixos/fedorivns-thinkpad/` (or equivalent) — add `vlc` to `home.packages`

## Capabilities

### New Capabilities

- `corp-software-gates`: Strategy for keeping shared modules lean by placing personal-preference packages in host configs, and using `programs.*` enable options (with `mkDefault`) for modules where opt-out is needed. A future corp host omits the personal host additions and overrides `programs.codex.enable = false`.

### Modified Capabilities

(none)

## Impact

- **modules/home/packages.nix** — three packages removed from shared lists
- **modules/home/whisply.nix** — gains `options.programs.whisply.enable`; existing behaviour preserved via `default = true`
- **modules/home/codex.nix** — one-line change; no behaviour change on existing hosts
- **modules/darwin/homebrew.nix** — three casks removed
- **configurations/darwin/fedorivns-mbp/default.nix** — gains personal package/cask additions
- **configurations/nixos/fedorivns-thinkpad/** — gains `vlc`
- All other hosts unaffected; no new option namespace introduced
