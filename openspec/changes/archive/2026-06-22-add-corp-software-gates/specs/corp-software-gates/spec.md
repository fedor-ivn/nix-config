## ADDED Requirements

### Requirement: whisply module is opt-out via programs.whisply.enable
The `modules/home/whisply.nix` module SHALL expose `options.programs.whisply.enable` using `lib.mkEnableOption` with `default = true`. All module config (sops secret, home.packages wrapper script) SHALL be conditional on this option. Any host MAY set `programs.whisply.enable = false` to suppress the module without `mkForce`.

#### Scenario: Default activation
- **WHEN** a host does not set `programs.whisply.enable`
- **THEN** whisply is installed and the sops secret is active (same as before this change)

#### Scenario: Corp host opt-out
- **WHEN** a host sets `programs.whisply.enable = false`
- **THEN** whisply is not installed and no sops secret is requested

### Requirement: codex is overridable via mkDefault
The `modules/home/codex.nix` module SHALL set `programs.codex.enable = lib.mkDefault true` so that any host config can override it to `false` at normal priority without requiring `lib.mkForce`.

#### Scenario: Default activation
- **WHEN** a host does not set `programs.codex.enable`
- **THEN** codex is enabled (same as before this change)

#### Scenario: Host override
- **WHEN** a host sets `programs.codex.enable = false`
- **THEN** codex is disabled and no conflict error occurs at eval time

### Requirement: iina and zoom-us are MBP-only via host config
`iina` and `zoom-us` SHALL be removed from `modules/home/packages.nix` and added exclusively to `configurations/darwin/fedorivns-mbp/default.nix` under `home-manager.users.fedorivn.home.packages`. They SHALL NOT appear in any shared module.

#### Scenario: MBP build
- **WHEN** the fedorivns-mbp configuration is built
- **THEN** iina and zoom-us are present in the home-manager package closure

#### Scenario: ThinkPad build
- **WHEN** the fedorivns-thinkpad configuration is built
- **THEN** iina and zoom-us are absent from the package closure

### Requirement: vlc is ThinkPad-only via host config
`vlc` SHALL be removed from `modules/home/packages.nix` and added to `configurations/nixos/fedorivns-thinkpad/default.nix` under `home-manager.users.fedorivn.home.packages`.

#### Scenario: ThinkPad build
- **WHEN** the fedorivns-thinkpad configuration is built
- **THEN** vlc is present in the home-manager package closure

#### Scenario: MBP build
- **WHEN** the fedorivns-mbp configuration is built
- **THEN** vlc is absent from the package closure

### Requirement: Personal homebrew casks are MBP-only via host config
`chatgpt`, `claude`, and `altserver` casks SHALL be removed from `modules/darwin/homebrew.nix` and added to `configurations/darwin/fedorivns-mbp/default.nix` under `homebrew.casks`. The shared homebrew module SHALL NOT reference these casks.

#### Scenario: MBP homebrew activation
- **WHEN** the fedorivns-mbp configuration is activated
- **THEN** chatgpt, claude, and altserver are included in the homebrew cask list

#### Scenario: No behaviour change on MBP
- **WHEN** comparing pre- and post-change MBP activation
- **THEN** the effective set of installed casks is identical
