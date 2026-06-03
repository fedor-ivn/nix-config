## ADDED Requirements

### Requirement: Module path and import shape

The repo SHALL provide a reusable headless-server module at
`modules/nixos/server/` with a `default.nix` that can be
imported by any NixOS host configuration in
`configurations/nixos/<host>/default.nix`.

#### Scenario: Module is auto-exposed via nixos-unified

- **WHEN** the flake is evaluated
- **THEN** the module is reachable as
  `self.nixosModules.server` (matching the auto-wiring of other
  modules under `modules/nixos/`)

#### Scenario: Importing the module compiles

- **WHEN** a host's `default.nix` imports the server module
- **THEN** `nixos-rebuild build` succeeds with no missing-option
  errors attributable to the module

### Requirement: No graphical session

The server baseline SHALL ensure the system has no graphical
environment enabled. It SHALL set the X server and any display
manager to disabled and SHALL NOT import any module from
`modules/nixos/gui/`.

#### Scenario: X is disabled

- **WHEN** a host importing the baseline is evaluated
- **THEN** `services.xserver.enable` resolves to `false`

#### Scenario: No display manager runs at boot

- **WHEN** a host importing the baseline boots
- **THEN** `systemctl status display-manager.service` reports
  the unit as not-found or inactive

### Requirement: SSH-only remote access

The baseline SHALL enable `openssh` and SHALL configure it to
refuse password authentication, accepting only public-key
authentication. Root login SHALL be disabled (or restricted to
forced-commands-only, matching the existing repo convention).

#### Scenario: Password login is refused

- **WHEN** an SSH client attempts password authentication
- **THEN** the server refuses the connection with a permission
  failure

#### Scenario: Public-key login succeeds

- **WHEN** an SSH client connects with a key listed in
  `users.users.fedorivn.openssh.authorizedKeys.keys`
- **THEN** the connection is accepted

### Requirement: Lid switch is ignored

The baseline SHALL set `services.logind.lidSwitch = "ignore"`
(and the external-power and docked variants) so a laptop host
with the lid closed does not suspend.

#### Scenario: Closing the lid does not suspend

- **WHEN** a host importing the baseline has its lid closed
- **THEN** the system continues running and remains reachable
  via SSH

### Requirement: Suspend on AC is disabled

The baseline SHALL configure the system so that, on AC power,
it never enters suspend or hibernate states automatically.

#### Scenario: System stays running on idle

- **WHEN** a host importing the baseline is left idle on AC for
  one hour
- **THEN** the system has not transitioned to suspend or
  hibernate (verifiable in `journalctl -u systemd-suspend`)

### Requirement: Time synchronization enabled

The baseline SHALL enable a time-synchronization service
(`services.timesyncd.enable = true` or equivalent) so the host
clock stays accurate for sops decryption, TLS, and logs.

#### Scenario: timesyncd is active

- **WHEN** a host importing the baseline is queried
- **THEN** `systemctl is-active systemd-timesyncd.service`
  returns `active`

### Requirement: Firewall enabled with conservative defaults

The baseline SHALL enable the NixOS firewall
(`networking.firewall.enable = true`) and SHALL open only SSH
(TCP 22) by default. Hosts importing the baseline can open
additional ports per service.

#### Scenario: SSH port is open

- **WHEN** a host importing the baseline is reachable on the
  LAN
- **THEN** TCP port 22 accepts inbound connections

#### Scenario: An arbitrary port is closed

- **WHEN** an external client attempts to connect to TCP port
  8080 on a host importing the baseline without that port
  being explicitly opened
- **THEN** the connection is refused or dropped

### Requirement: Bounded journald disk usage

The baseline SHALL cap journald on-disk usage to a bounded size
(e.g., `services.journald.extraConfig` setting `SystemMaxUse`)
so logs cannot fill the small root partition on an idle host.

#### Scenario: SystemMaxUse is set

- **WHEN** the journald configuration is inspected
- **THEN** `SystemMaxUse` is present and resolves to a finite
  value (not unset / unlimited)
