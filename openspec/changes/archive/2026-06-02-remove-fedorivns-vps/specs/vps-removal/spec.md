## REMOVED Requirements

### Requirement: fedorivns-vps host configuration
**Reason**: The VPS is decommissioned and no longer in use. The config was the
only definition of the `fedorivns-vps` NixOS system in the flake.
**Migration**: N/A — host is gone. Any future VPS would be a new host entry.

#### Scenario: VPS absent from flake outputs
- **WHEN** `nix flake show` is run
- **THEN** `fedorivns-vps` SHALL NOT appear under `nixosConfigurations`

#### Scenario: Flake check passes without VPS
- **WHEN** `nix flake check` is run
- **THEN** the check SHALL complete without attempting to evaluate `fedorivns-vps`

### Requirement: vps-lima SSH host alias
**Reason**: The alias pointed at a local port-forward to the now-decommissioned VPS.
**Migration**: N/A — the tunnel and host are gone.

#### Scenario: vps-lima absent from SSH config
- **WHEN** the home-manager SSH config is activated
- **THEN** `~/.ssh/config` SHALL NOT contain a `Host vps-lima` block
