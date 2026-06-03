## ADDED Requirements

### Requirement: ThinkPad excludes heavy unused GUI packages
The ThinkPad NixOS installation SHALL NOT include heavy GUI applications that are not actively used as daily drivers on that machine (`slack`, `zoom-us`, `qbittorrent`, `libreoffice`, `ungoogled-chromium`). These SHALL be placed in a dedicated `thinkpadOnly` package list included only when `!config.me.isMainMachine` (i.e., on Linux/ThinkPad).

#### Scenario: Heavy apps absent from macOS nix profile
- **WHEN** the `fedorivns-mbp` Home Manager configuration is evaluated
- **THEN** `slack`, `zoom-us`, `qbittorrent`, `libreoffice`, and `ungoogled-chromium` SHALL NOT appear in `home.packages` from `packages.nix`

#### Scenario: Heavy apps present on ThinkPad
- **WHEN** the `fedorivns-thinkpad` Home Manager configuration is evaluated
- **THEN** `slack`, `zoom-us`, `qbittorrent`, `libreoffice`, and `ungoogled-chromium` SHALL appear in `home.packages`

### Requirement: `hoppscotch` removed from all hosts
`hoppscotch` SHALL be removed from the `base` package list and SHALL NOT be installed on any host, as `posting` covers the HTTP testing use case.

#### Scenario: `hoppscotch` absent from all profiles
- **WHEN** any host's Home Manager configuration is evaluated
- **THEN** `hoppscotch` SHALL NOT appear in `home.packages`
