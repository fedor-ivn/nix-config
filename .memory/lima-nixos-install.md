# Lima NixOS Install Guide (Exact Runbook)

## Summary
This runbook documents the exact flow used to install NixOS in the `nixos-vm` Lima VM for this repo, including the failed first attempt and the successful recovery path.

## Preconditions
- Host OS: macOS
- Lima installed and available as `limactl`
- Repo path: `/Users/fedorivn/projects/nix-config`
- Flake host: `.#fedorivns-vps`
- SSH key for Lima guest access: `/Users/fedorivn/.lima/_config/user`
- VM name: `nixos-vm`
- SSH forwarded port is fixed to `53555` via `modules/darwin/lima-nixos-vm.yaml`

---

## Step 0: Validate local prerequisites

Run:

```sh
limactl --version
limactl list
nix build .#nixosConfigurations.fedorivns-vps.config.system.build.toplevel --dry-run
```

Expected:
- `limactl` is installed and returns a version.
- `limactl list` works (VM may be running/broken/stopped; all are recoverable).
- Flake target evaluates (`--dry-run` succeeds).

If `nix build --dry-run` fails:
- Fix flake/config errors first.
- Do not run installer until this build step succeeds.

---

## Step 1: Recreate Lima VM from repo template (clean state)

This ensures a deterministic install target and avoids unknown VM drift from prior attempts.

Run:

```sh
limactl stop nixos-vm || true
limactl delete -f nixos-vm || true
limactl create --yes --name=nixos-vm /Users/fedorivn/projects/nix-config/modules/darwin/lima-nixos-vm.yaml
limactl start nixos-vm
limactl list
```

Use the fixed SSH forwarded port:

```sh
LIMA_PORT=31337
```

---

## Step 2: Verify Debian bootstrap guest is reachable

Before installation, confirm Lima guest is still Debian:

```sh
ssh -F /Users/fedorivn/.lima/nixos-vm/ssh.config lima-nixos-vm 'id; cat /etc/os-release | head -n 3'
```

Expected:
- User is `fedorivn` in guest.
- `/etc/os-release` shows Debian 12 (Bookworm).

### Why the SSH command looks weird

This setup uses Lima port forwarding and automation-friendly SSH flags:
- `root@127.0.0.1 -p "$LIMA_PORT"`: Lima exposes guest SSH on localhost with a fixed forwarded port.
- `-i /Users/fedorivn/.lima/_config/user`: forces Lima's VM key.
- `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`: avoids host-key mismatch failures after VM recreate/kexec.
- Quoted command (`'...'`): runs verification commands remotely in one SSH call.

Daily-use interactive variant (cleaner):

```sh
ssh -i /Users/fedorivn/.lima/_config/user -p "$LIMA_PORT" root@127.0.0.1
```

---

## Step 3: First install attempt (failed path and reason)

Initial command:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake /Users/fedorivn/projects/nix-config#fedorivns-vps \
  --target-host fedorivn@127.0.0.1 \
  --ssh-port "$LIMA_PORT" \
  -i /Users/fedorivn/.lima/_config/user
```

Observed behavior:
- `kexec` bootstrap succeeds.
- Then `nixos-anywhere` loops reconnect attempts to `127.0.0.1:22`.

Root cause:
- `nixos-anywhere` defaults post-kexec reconnect port to `22`.
- Lima forwards guest SSH to a fixed localhost port (`31337`), not guest port `22`.

---

## Step 4: Recovery path that succeeded

At this point, the VM is already in the NixOS installer environment.

1. Confirm installer is reachable on forwarded port:

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i /Users/fedorivn/.lima/_config/user \
  -p "$LIMA_PORT" root@127.0.0.1 'echo up; uname -a'
```

2. Resume install without re-running kexec:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake /Users/fedorivn/projects/nix-config#fedorivns-vps \
  --target-host root@127.0.0.1 \
  --ssh-port "$LIMA_PORT" \
  -i /Users/fedorivn/.lima/_config/user \
  --phases disko,install,reboot
```

Why skipping `kexec` is correct:
- The first attempt already kexec-booted the machine into the installer.
- Re-running full flow is unnecessary and can add failure surface.
- Continuing with `disko,install,reboot` uses the current installer state directly.

Expected final log line:
- `### Done! ###`

---

## Step 5: Post-install verification

Run:

```sh
limactl list
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i /Users/fedorivn/.lima/_config/user \
  -p "$LIMA_PORT" root@127.0.0.1 \
  'hostnamectl; cat /etc/os-release | sed -n "1,6p"; lsblk -f'
```

Expected:
- VM is `Running` in `limactl list`.
- `hostnamectl` reports `Static hostname: fedorivns-vps`.
- `/etc/os-release` reports `NixOS 26.05`.
- `lsblk -f` shows:
  - `vda1` as `vfat` mounted at `/boot`
  - `vda2` as `ext4` mounted at `/`

---

## Troubleshooting (minimal)

### Lima VM shows `Broken`
Try:

```sh
limactl stop nixos-vm || true
limactl start nixos-vm
limactl list
```

If still unstable, recreate VM from Step 1.

### Host command sandbox/permissions issues
When running through a restricted execution environment, Lima host commands may fail with permission errors for sockets/processes. Run the same `limactl`/`ssh` commands directly in your local shell or with elevated execution permissions.

### Reconnect loop to port 22 after kexec
Use one of:
- Recovery flow from Step 4 (`--phases disko,install,reboot` on forwarded port).
- One-pass install command that pins post-kexec port (see next section).

---

## Future rerun shortcut (clean install checklist)

1. Validate:

```sh
limactl --version
limactl list
nix build .#nixosConfigurations.fedorivns-vps.config.system.build.toplevel --dry-run
```

2. Recreate VM:

```sh
limactl stop nixos-vm || true
limactl delete -f nixos-vm || true
limactl create --yes --name=nixos-vm /Users/fedorivn/projects/nix-config/modules/darwin/lima-nixos-vm.yaml
limactl start nixos-vm
limactl list
```

3. Set port and run one-pass install:

```sh
LIMA_PORT=31337

nix run github:nix-community/nixos-anywhere -- \
  --flake /Users/fedorivn/projects/nix-config#fedorivns-vps \
  --target-host fedorivn@127.0.0.1 \
  --ssh-port "$LIMA_PORT" \
  --post-kexec-ssh-port "$LIMA_PORT" \
  -i /Users/fedorivn/.lima/_config/user
```

4. Verify:

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i /Users/fedorivn/.lima/_config/user \
  -p "$LIMA_PORT" root@127.0.0.1 \
  'hostnamectl; cat /etc/os-release | head -n 6; lsblk -f'
```

---

## Validation Scenarios for This Guide
1. Doc accuracy check:
   - Re-run on a fresh VM and confirm same final host/partition state.
2. Failure-path check:
   - Ensure reconnect-to-22 issue and recovery are explicitly documented.
3. Copy-paste check:
   - Every command block runs with only `$LIMA_PORT` adjusted.
4. Final verification check:
   - Includes `hostnamectl`, `os-release`, and `lsblk -f` concrete indicators.
