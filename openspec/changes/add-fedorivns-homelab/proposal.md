## Why

The ThinkPad currently runs the `fedorivns-thinkpad` GUI NixOS
desktop config but sees rare daily use — the MacBook Pro is the
actual daily driver. The hardware is otherwise idle and could host a
24/7 headless homelab. The desktop role is still wanted ~once a year
for experiments, so the existing install must keep booting. This
change stands up an empty headless host (`fedorivns-homelab`) on the
same physical ThinkPad via dual-boot. Services, backups, and any
data partition layout are deliberately deferred to future changes.

## What Changes

- Add a new headless NixOS host **`fedorivns-homelab`** that runs on
  the same physical ThinkPad as `fedorivns-thinkpad`, alongside the
  existing GUI install as a dual-boot.
- Repartition the ThinkPad disk once: shrink the existing root and
  add a new LUKS root partition for the homelab role. Leave the
  remaining space unallocated so future changes can decide its use
  without another shrink.
- Auto-unlock the homelab root via TPM2 (`systemd-cryptenroll`) so
  the headless host survives unattended reboots.
- Configure a shared `systemd-boot` ESP so both hosts appear in the
  boot menu; `fedorivns-homelab` is the default with a short timeout
  and `default = @saved` semantics.
- Introduce **`modules/nixos/server/`** — a reusable headless-server
  baseline (ssh-only, no GUI, `logind.lidSwitch = "ignore"`, sane
  always-on defaults).
- Add the homelab host's ssh host key as an age recipient in
  `.sops.yaml` and re-encrypt `secrets.yaml`.
- Pin a static DHCP IP for the homelab and set
  `nixos-unified.sshTarget` for `just a` deploys.

The existing `fedorivns-thinkpad` config remains bootable and
functionally unchanged.

## Capabilities

### New Capabilities

- `homelab-host`: The `fedorivns-homelab` flake host itself —
  dual-boot coexistence with `fedorivns-thinkpad`, the one-time
  disk repartition (shrink + homelab-root + unallocated free space),
  TPM2 unattended unlock, `systemd-boot` shared-ESP defaults, sops
  age recipient, static-DHCP pin, and `nixos-unified.sshTarget`.
- `server-baseline`: Reusable headless-server module at
  `modules/nixos/server/`. Captures conventions for any future
  server host (ssh-only access, no GUI, `lidSwitch = "ignore"`,
  firewall defaults, time sync, journald limits).

### Modified Capabilities

None. `openspec/specs/` is empty; this change introduces
capabilities rather than modifying them.

## Impact

- **Hardware (one-time):** ThinkPad disk is repartitioned. The
  existing root is shrunk; a new `homelab-root` LUKS partition is
  added; remaining space is left unallocated. A backup of the
  existing root is required before the operation.
- **Flake structure:**
  - New `configurations/nixos/fedorivns-homelab/` directory
    (`default.nix`, `hardware.nix`).
  - New `modules/nixos/server/` tree.
- **Existing flake hosts:**
  - `fedorivns-thinkpad`: untouched.
  - `fedorivns-mbp`: untouched.
- **Secrets:** `.sops.yaml` gains the homelab host's age recipient;
  `secrets.yaml` is re-encrypted to include it. The shared user
  age key is unaffected.
- **Bootloader:** Both NixOS installs share a single ESP under
  `systemd-boot`. The `loader.conf default` pointer flaps to
  whichever host was last activated; mitigated with
  `default = @saved`.
- **Networking:** Homelab gets its own static-DHCP IP and
  `nixos-unified.sshTarget`. No change to the existing thinkpad
  network pin.
- **Out of scope** (each is a candidate future change):
  - Any service (Syncthing move, Vaultwarden, Paperless, Immich,
    file sharing, k3s, etc.).
  - A `/srv/data` partition or any data-partition layout — space
    is reserved but the partition is not created here.
  - Restic or any backup strategy.
  - State-path conventions, service UID/GID pinning, bind-mount
    patterns.
  - A future `fedorivns-nuc` host.
