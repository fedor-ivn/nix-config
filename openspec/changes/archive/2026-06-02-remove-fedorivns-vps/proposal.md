## Why

The `fedorivns-vps` host is no longer in use and its config is dead weight in the
flake — it bloats `nix flake check`, wastes mental overhead, and the `vps-lima`
SSH alias in the home config is an artifact of a gone machine. Removing it now
also cleans up a stale reference before the `add-fedorivns-homelab` change lands.

## What Changes

- **BREAKING** Delete `configurations/nixos/fedorivns-vps/` (the host directory
  and its `default.nix`).
- Remove the `vps-lima` SSH host entry from `modules/home/ssh.nix`.
- Update `openspec/changes/add-fedorivns-homelab/` artifacts that reference
  `fedorivns-vps` as an existing host (design.md, proposal.md) so they no longer
  describe a host that does not exist.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. `openspec/specs/` is empty; no persisted spec is affected by the removal.

## Impact

- **Flake:** `fedorivns-vps` disappears from `nixosConfigurations`. `nix flake
  check` and `nix flake show` no longer attempt to evaluate it.
- **Home config:** `modules/home/ssh.nix` loses the `vps-lima` block (hostname
  `127.0.0.1`, port `53555`, user `root`).
- **Secrets / SOPS:** `.sops.yaml` has no VPS-specific age recipient — no
  re-encryption needed.
- **Homelab change docs:** `add-fedorivns-homelab/{proposal,design}.md` mention
  the VPS as an existing host and as a possible future retrofit target. Those
  references are updated to reflect that the host has been removed.
- **No other hosts affected.** `fedorivns-thinkpad` and `fedorivns-mbp` do not
  import or reference the VPS configuration.
