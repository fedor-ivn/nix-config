## ADDED Requirements

### Requirement: Flake host directory exists

The flake SHALL define a NixOS host named `fedorivns-homelab` at
`configurations/nixos/fedorivns-homelab/` with at least
`default.nix` and `hardware.nix`, picked up by nixos-unified's
auto-wiring.

#### Scenario: Auto-wiring resolves the host

- **WHEN** the user runs `nix flake show` against this repo
- **THEN** the output includes `nixosConfigurations.fedorivns-homelab`

#### Scenario: Activation entry point works

- **WHEN** the user runs `just a` from the homelab host
- **THEN** the build resolves `fedorivns-homelab` and applies it
  without manual host selection

### Requirement: Headless system platform

The host SHALL declare `system = "x86_64-linux"` (matching the
ThinkPad hardware) and SHALL NOT import any GUI module from
`modules/nixos/gui/`.

#### Scenario: No graphical session is enabled

- **WHEN** the system configuration is evaluated
- **THEN** `services.xserver.enable` resolves to `false` and no
  display manager is enabled

### Requirement: Host imports the server baseline

The `default.nix` for `fedorivns-homelab` SHALL import
`modules/nixos/server/` so the host inherits the headless-server
conventions.

#### Scenario: Lid switch policy applied via baseline

- **WHEN** the homelab system is built
- **THEN** `services.logind.lidSwitch` resolves to `"ignore"`
  (set by the imported `server-baseline` module)

### Requirement: Dual-boot coexistence with `fedorivns-thinkpad`

The `fedorivns-homelab` configuration SHALL coexist on the same
physical ThinkPad as `fedorivns-thinkpad` without requiring
changes to the latter's configuration. Both hosts SHALL boot
from a shared EFI System Partition under `systemd-boot`.

#### Scenario: Existing thinkpad host config untouched

- **WHEN** this change is applied
- **THEN** `configurations/nixos/fedorivns-thinkpad/default.nix`
  contains no modifications (verifiable in `git diff`)

#### Scenario: Both entries appear in the boot menu

- **WHEN** the user reboots the ThinkPad
- **THEN** the `systemd-boot` menu lists at least one entry for
  each host's NixOS generations

### Requirement: Homelab is the default boot entry

The `systemd-boot` configuration SHALL set the homelab as the
default selection with a short timeout, using saved-entry
semantics so the user's last manual selection persists across
activations.

#### Scenario: Default selection on a fresh boot menu

- **WHEN** no `@saved` selection exists yet (first boot after
  install)
- **THEN** the highlighted default entry corresponds to
  `fedorivns-homelab`

#### Scenario: Manual selection persists across reboots

- **WHEN** the user selects the desktop entry at the boot menu
- **AND** reboots without manually selecting again
- **THEN** the same desktop entry is the highlighted default

#### Scenario: Timeout is short

- **WHEN** the boot menu is displayed
- **THEN** `boot.loader.timeout` resolves to a value of 5
  seconds or less

### Requirement: Unattended TPM2 root unlock

The `homelab-root` LUKS partition SHALL be unlocked at boot via a
TPM2-bound keyslot enrolled with `systemd-cryptenroll`, with a
passphrase as a fallback keyslot. No user input SHALL be
required for a normal boot.

#### Scenario: Cold boot succeeds without keyboard input

- **WHEN** the ThinkPad is powered on with no keyboard attached
- **AND** the firmware state matches the sealed PCRs
- **THEN** the system reaches the login prompt without
  prompting for a LUKS passphrase

#### Scenario: Passphrase fallback remains available

- **WHEN** the TPM2 unlock fails (PCR mismatch after firmware
  change)
- **THEN** the LUKS partition can still be opened by entering
  the enrolled passphrase

### Requirement: SOPS age recipient for the host

The repo's `.sops.yaml` SHALL include the `fedorivns-homelab`
ssh host key as an age recipient, and `secrets.yaml` SHALL be
re-encrypted so the host can decrypt secrets at boot via
sops-nix.

#### Scenario: Host decrypts its own secrets

- **WHEN** the homelab boots
- **THEN** sops-nix decrypts `secrets.yaml` using the host's
  ssh host key, with no manual intervention

### Requirement: Networking pinned for deploys

The host SHALL have a static-DHCP IP reservation on the local
network, and the configuration SHALL set
`nixos-unified.sshTarget = "fedorivn@<homelab-ip>"` so `just a`
deploys from the user's daily-driver MBP target the homelab
reliably.

#### Scenario: Deploy from MBP reaches the homelab

- **WHEN** the user runs `just a` on the MBP and selects
  `fedorivns-homelab`
- **THEN** the deploy connects to the pinned IP and activates a
  new generation

### Requirement: Disk layout reserves future space

After the one-time repartition, the ThinkPad disk SHALL contain
the original ESP, the shrunk existing root, a new `homelab-root`
LUKS partition (sized for the homelab OS), and unallocated free
space for future use. No `/srv/data` or other data partition
SHALL be created by this change.

#### Scenario: Free space is available

- **WHEN** the user runs `lsblk -f` on the homelab after install
- **THEN** at least one unpartitioned free-space region is
  present on the disk

#### Scenario: No data partition mounted

- **WHEN** the homelab boots
- **THEN** `mount | grep /srv/data` produces no output
