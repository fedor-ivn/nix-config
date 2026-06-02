## Context

The flake currently has three hosts: `fedorivns-thinkpad`, `fedorivns-mbp`, and
`fedorivns-vps`. The VPS is no longer running. Its configuration
(`configurations/nixos/fedorivns-vps/default.nix`) still exists in the repo and
is evaluated by `nix flake check`. A `vps-lima` SSH alias in
`modules/home/ssh.nix` was used to reach the VPS via a local port-forward (port
53555); that machine is gone.

The `add-fedorivns-homelab` change's design and proposal documents describe
`fedorivns-vps` as an existing host — the template used for context when designing
the server-baseline module. Those references now describe a host that no longer
exists.

## Goals / Non-Goals

**Goals:**

- Remove `fedorivns-vps` from `nixosConfigurations` so it is never evaluated.
- Remove the `vps-lima` SSH host block from the shared home SSH config.
- Update the in-flight `add-fedorivns-homelab` change docs to not reference
  a removed host.

**Non-Goals:**

- Removing any SSH known-hosts entries (managed outside the flake).
- Updating secrets.yaml / .sops.yaml (VPS had no per-host age recipient).
- Adopting `server-baseline` retroactively on any host (deferred to homelab change).
- Any change to `openspec/config.yaml` context (already lists only thinkpad + mbp).

## Decisions

### Decision 1: Delete the directory, not just disable

Remove `configurations/nixos/fedorivns-vps/` entirely rather than leaving it as a
commented-out config or an empty stub.

**Rationale:** nixos-unified auto-wires by directory presence. Leaving an empty or
commented directory would still be picked up, requiring an awkward exclude guard.
Deletion is clean and is the idiomatic "host is gone" signal.

**Alternatives considered:**

- *Comment out the import.* Nix ignores comments but the directory still exists;
  `nix flake show` would still list the host. Rejected.
- *Leave as-is.* The dead config evaluates on every `nix flake check`, wastes
  time, and misleads readers. Rejected.

### Decision 2: Update homelab change docs in-place

Edit `add-fedorivns-homelab/proposal.md` and `add-fedorivns-homelab/design.md`
rather than leaving stale references.

**Rationale:** The homelab change is unarchived and in-flight. Its docs describe
`fedorivns-vps` as a currently-existing host and as a future retrofit candidate.
Updating them now keeps the change's context accurate before anyone starts
implementing it.

**What to update:**
- `design.md`: Remove `fedorivns-vps` from the "Context" host list; remove the
  "Drift between homelab and vps" risk entry; remove the "Migrating
  fedorivns-vps onto server-baseline" non-goal entry.
- `proposal.md`: Remove the `fedorivns-vps: untouched` bullet from the Impact
  section.

## Risks / Trade-offs

- **Accidental removal of needed SSH config** → `vps-lima` was the only reference
  to that port-forward alias; `grep` confirms no other config imports or
  references it. Low risk.
- **Homelab change tasks already in progress** → if task 3 (flake scaffolding) is
  already underway, the design doc update is cosmetic and does not invalidate any
  implementation step. The tasks.md is unaffected.
