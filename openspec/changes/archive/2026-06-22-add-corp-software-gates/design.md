## Context

Shared home-manager modules in `modules/home/` are auto-imported for all hosts via `modules/home/default.nix`. Several packages currently live in these shared modules but are personal-preference items that should not be assumed present on every machine — particularly a future corp laptop.

The change uses two complementary techniques depending on what is being removed:
- **Move to host config** — for packages and casks that are purely personal-preference (no module logic around them)
- **`programs.*` enable option** — for modules with real configuration logic that need an on/off switch

## Goals / Non-Goals

**Goals:**
- Remove personal-preference packages from shared modules into the MBP and ThinkPad host configs
- Give `whisply` a proper `programs.whisply.enable` opt-in/opt-out option
- Make `codex` overridable from a host config without `mkForce`
- Leave all current hosts with identical behaviour post-change

**Non-Goals:**
- Creating a corp host configuration (that is a follow-on change)
- Gating any W/G-category software (allowed by registry)
- Introducing a custom option namespace (`my.*`, `corp.*`, etc.)

## Decisions

### Personal packages move to host configs, not gated by `isMainMachine`

**Decision**: Add `iina` and `zoom-us` to `configurations/darwin/fedorivns-mbp/default.nix` via `home-manager.users.fedorivn.home.packages`; add `vlc` to `configurations/nixos/fedorivns-thinkpad/default.nix` the same way.

**Rationale**: `configurations/home/fedorivn.nix` is the shared home baseline and should not accumulate host-specific conditionals. The host config is the right owner for host-specific additions. The `home-manager.users.<user>.home.packages` key merges with whatever the shared home modules define, so no existing packages are displaced.

**Alternative considered**: Gate with `config.me.isMainMachine` inside the shared home config. Rejected — it leaks host identity into a shared file and contradicts the purpose of per-host configs.

### `programs.whisply.enable` defaults to `true`

**Decision**: Use `lib.mkEnableOption "whisply" // { default = true; }` rather than the standard `false` default.

**Rationale**: The canonical `mkEnableOption` default is `false` (opt-in). For an existing module, flipping to `false` would break the ThinkPad and MBP silently on the next activation. Defaulting to `true` preserves current behaviour; the corp host explicitly sets it to `false`.

**Trade-off**: Diverges from HM convention. Acceptable because this is a personal config, not a public module.

### `codex` uses `lib.mkDefault` rather than a new option

**Decision**: Change `programs.codex.enable = true` to `programs.codex.enable = lib.mkDefault true`.

**Rationale**: `programs.codex` is a home-manager option that already exists. `mkDefault` sets priority 1000, meaning any host-level `programs.codex.enable = false` wins without needing `mkForce`. No new option needs to be defined.

### Homebrew casks move to host config, not filtered by options

**Decision**: Remove `chatgpt`, `claude`, `altserver` from `modules/darwin/homebrew.nix` and add them to `configurations/darwin/fedorivns-mbp/default.nix` under `homebrew.casks`.

**Rationale**: `homebrew.casks` is a list type in nix-darwin — it merges across all darwin modules. The host config appending to it is idiomatic and requires no option plumbing in the shared module.

## Risks / Trade-offs

- **`vlc` on ThinkPad** — currently in `linuxOnlyGuiApps` so it was linux-only already; moving it to the ThinkPad host config is safe. If a second linux host is ever added it won't get `vlc` by default, which is the intended behaviour.
- **`zoom-us` removal from shared** — currently behind `isDarwin` guard anyway; moving to MBP host is a no-op for the ThinkPad.
- **`whisply` default `true`** — if a new host is added and does not explicitly disable it, whisply activates. Low risk given the flake-level gating on `isDarwin` still inside the module.

## Migration Plan

1. Remove `vlc`, `zoom-us`, `iina` from `modules/home/packages.nix`
2. Add them to the respective host configs
3. Remove `chatgpt`, `claude`, `altserver` from `modules/darwin/homebrew.nix`
4. Add them to `configurations/darwin/fedorivns-mbp/default.nix`
5. Update `modules/home/whisply.nix` with the enable option
6. Update `modules/home/codex.nix` to use `mkDefault`
7. Build and activate on MBP (`just a`) to verify no regressions

Rollback: revert the moved items back to the shared modules — no state changes, no data migration.

## Open Questions

- Should `zoom-us` stay darwin-only or is it wanted on a future linux corp host too? (Currently implicitly darwin-only via `baseGuiApps` guard — moving to MBP host config makes that explicit.)
