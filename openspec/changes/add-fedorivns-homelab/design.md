## Context

The flake currently defines three hosts:

- `fedorivns-thinkpad` — x86_64-linux NixOS, GUI desktop, syncthing,
  LUKS-encrypted root, daily-driver-by-history but in practice idle.
- `fedorivns-mbp` — aarch64-darwin, the actual current daily driver.
The ThinkPad is the target hardware. It must remain bootable as the
existing GUI desktop ~once a year for experiments, but otherwise run
a 24/7 headless homelab role. There is no headless-server module
shared between hosts yet.

Constraints:

- Existing thinkpad install must survive the disk surgery and stay
  bootable.
- Homelab role is headless — no keyboard or display attached during
  normal operation, so any boot-time prompt (LUKS passphrase) is
  effectively a wedge.
- Activation flow stays `just a` (nixos-unified).
- SOPS uses a single shared user age key
  (`age1tekqv95zmy8yu6t6938n2ctqctd5r7q099679vaqqjzzqs5l5yaqkyx3sq`);
  per-host secrets are decrypted via the host's ssh host key as an
  additional age recipient.

## Goals / Non-Goals

**Goals:**

- A bootable, ssh-able, empty `fedorivns-homelab` host on the
  ThinkPad, deployable via `just a` like any other host.
- Reusable `modules/nixos/server/` baseline so a future server host
  (`fedorivns-vps` retrofit, or a new box) imports the same
  conventions instead of duplicating them.
- Unattended boot: no human interaction required after power-on.
- Existing `fedorivns-thinkpad` GUI install remains bootable and
  unchanged.

**Non-Goals:**

- Any service (Syncthing move, Vaultwarden, Immich, k3s, file
  sharing, etc.).
- Creating a `/srv/data` partition. Space is reserved as
  unallocated; the partition is created by a future change when a
  service needs it.
- Restic / backup strategy.
- Service state conventions (bind-mounts, UID/GID pinning).
- Adding `fedorivns-nuc` or designing for a hardware swap.

## Decisions

### Decision 1: Dual-boot on shared hardware (vs VM-under-desktop)

Run `fedorivns-homelab` as a second NixOS install on the same disk,
selectable via the bootloader. Reject running it as a VM under the
existing desktop install.

**Rationale:** A VM costs hypervisor overhead, contends for RAM
with the desktop, and ties the homelab's uptime to the desktop's
reboot/sleep cycle. The "24/7 always-on" goal contradicts running
inside a laptop desktop session. Bare-metal is also simpler:
networking is direct, no IOMMU passthrough, no nested
filesystem state to back up.

**Alternatives considered:**

- *VM under desktop NixOS (microvm.nix / qemu).* Rejected for the
  reasons above.
- *Full takeover (wipe existing install, single headless role).*
  Rejected because the desktop role is still wanted ~once a year.
- *Live-USB for desktop sessions.* Rejected: experiments imply
  multi-day persistence; live media is hostile to that.

### Decision 2: Decoupled hostname `fedorivns-homelab`

The new host is named `fedorivns-homelab`, not
`fedorivns-thinkpad-lab` or similar.

**Rationale:** The name describes role, not hardware. If the role
later moves to different hardware, the host directory and IP pin
move unchanged.

**Alternatives considered:**

- *`fedorivns-thinkpad-lab`.* Couples name to hardware; awkward
  if the role outlives the ThinkPad.
- *`fedorivns-lab`.* Shorter, ambiguous with "experimental".
  `homelab` reads more clearly.

### Decision 3: Keep `fedorivns-thinkpad` untouched

The existing host configuration is not renamed and not edited in
this change.

**Rationale:** Smallest blast radius. Avoids churn on sops
recipients, syncthing device IDs, known_hosts, and existing
deploy pins for a role that's only used ~once a year. The
existing config keeps booting from its existing root partition.

### Decision 4: Shrink the existing root (vs nuke + disko)

Resize the current encrypted root partition down rather than
wiping the disk and recreating it with `disko`.

**Rationale:** Preserves the working desktop install with minimal
risk. The desktop install is rarely used and rarely rebuilt; a
full reinstall would force re-setup for marginal gain. The
homelab partition is new and can be disko-driven on its own.

**Alternatives considered:**

- *Nuke + full disko.* Reproducible disk layout for both hosts,
  but requires re-installing the desktop role. Cost > benefit for
  a yearly-use role.

### Decision 5: Per-host ESPs (revised after implementation)

Each NixOS install gets its own ESP. The thinkpad keeps the
original ESP (`/dev/nvme0n1p1`). The homelab moves to a new ESP
carved out as part of this change. Each host mounts only its own
ESP at `/boot`. UEFI firmware boot order picks the default at
power-on; the rarely-booted desktop role is selected with
`sudo efibootmgr -n <thinkpad-boot-id> && sudo reboot` from the
homelab over SSH, or via the firmware boot menu on physical
access. Both hosts revert to vanilla
`boot.loader.systemd-boot.enable = true;` with no
`extraInstallCommands`.

**Rationale (revised).** Original plan was a single shared ESP
with `default = @saved`. In practice it hit three concrete
failure modes:

1. **Global generation GC.** NixOS's `systemd-boot-builder.py`
   `garbage_collect()` deletes any
   `loader/entries/nixos-.+\.conf` not in the current rebuild's
   `gc_roots`. With both hosts writing entries that match the
   regex, each host's rebuild silently deletes the other's
   entries. The workaround — renaming each host's entries via
   `extraInstallCommands` to `{host}-nixos-generation-N.conf` —
   sidesteps the regex but is fragile: a missed rename leaves
   an orphan `nixos-generation-N.conf` eligible for GC by
   either host. We observed exactly this — an orphan
   `nixos-generation-4.conf` survived on the shared ESP after
   multiple rebuilds.
2. **`nixos-enter` recovery cross-store contamination.** When
   recovering one install from the other via `nixos-enter`, the
   chroot's bootloader install wrote entry files to the ESP but
   the EFI stubs were copied from the *host's* `/nix/store`
   (which `nixos-enter` bind-mounts), not the target's. Entries
   pointed at nonexistent stubs; the install was unbootable
   until rerun from a fresh live USB.
3. **`loader.conf default` clobbering.** Declaring
   `default @saved` is not possible via the
   `boot.loader.systemd-boot.extraConfig` mechanism:
   NixOS's installer writes the `default` line first and
   `systemd-boot` honors the first occurrence. The workaround
   is `extraInstallCommands` doing
   `sed -i '/^default /c\default @saved'`, which races between
   hosts. Upstream attempt to add `rememberLastChoice`
   ([nixpkgs#286672](https://github.com/NixOS/nixpkgs/pull/286672))
   stalled.

None of (1)–(3) are user error; all three follow from sharing
one ESP between two installs that each think they own the
bootloader. A native fix would require NixOS plumbing
`bootctl --entry-token=machine-id` (which would namespace entry
filenames per install and let `garbage_collect` scope itself
accordingly). That option is not exposed by the NixOS module and
has no open issue against nixpkgs (verified against
`nixos/modules/system/boot/loader/systemd-boot/systemd-boot-builder.py`
on master, 2026-06).

Two ESPs makes (1)–(3) structurally impossible: each host's GC,
recovery, and `loader.conf` operate on disjoint filesystems. The
cost is a one-shot UEFI boot-order toggle to enter the desktop
role, paid ~yearly.

**Alternatives considered:**

- *Shared ESP with rename + `default @saved` hack (what we
  actually built first).* Works but pays an ongoing tax on every
  activation and on every recovery. Three documented failure
  modes; see above.
- *`nixos-rebuild --profile-name` on a single install.* The
  cleanest NixOS-native answer to "two configurations, one
  bootloader" — the builder iterates
  `/nix/var/nix/profiles/system-profiles/*` and applies
  `configurationLimit` per-profile. But requires unifying
  `/nix/store` and `/` between the two roles, which loses
  Decision 6's "each role's state lives behind its own LUKS"
  property. Too invasive for the benefit.
- *`specialisation` within one install (Solene's "two NixOS as
  one" pattern).* Same blocker: specialisations share
  `/etc/machine-id`, `/var`, journal, and persistent state. A
  24/7 service host and a desktop should not share these.
- *Original "two ESPs" rejection.* Cited "extra fragility on
  firmware updates that reorder UEFI entries". In practice, on
  this ThinkPad in this physical location, that risk is far
  smaller than the per-activation friction of the shared-ESP
  hack.

### Decision 6: TPM2 auto-unlock via `systemd-cryptenroll`

The homelab root LUKS partition is unlocked at boot by a TPM2
binding (`systemd-cryptenroll --tpm2-device=auto`), with a
passphrase as the fallback enrolled keyslot.

**Rationale:** Headless boxes cannot answer a LUKS passphrase
prompt at 3am after a kernel-panic reboot. TPM2 on the ThinkPad
provides hardware-rooted automatic unlock that requires
possession of *this* machine in *this* firmware state.

**Trade-off:** PCR sealing can break on firmware/kernel changes
in ways the user must know how to recover from. Recovery path =
passphrase entry over a temporary keyboard, or via initrd-ssh
fallback (out of scope here; passphrase is acceptable for a
homelab).

**Alternatives considered:**

- *initrd SSH (dropbear-initrd).* Works, but adds a network
  stack to initrd and a second secret (the initrd ssh host key).
  Overkill for a homelab in a known physical location.
- *No encryption on homelab-root.* Simpler. Rejected because the
  data partition (future) will need to be encrypted, and using
  the same approach for the root keeps the model uniform.
- *Encrypt only data, not root.* Possible, but root contains
  `/etc/ssh` host keys and sops-decrypted secrets in
  `/run/secrets`. Encrypting root is the conservative default.

### Decision 7: Leave free space unallocated, modulo the new ESP

After shrinking the existing root and creating the new
`homelab-root` LUKS partition, the remaining disk space is left
unallocated — *except* for the new homelab ESP carved out as
part of Decision 5's revision. See tasks.md section 11 for the
carve-out source (TBD: repurpose `p3` if reclaimable, else
shrink `homelab-root` by ~1G).

**Rationale:** This change has no service that needs a data
partition yet. Pre-creating one would commit to a layout
(single partition, btrfs subvolumes, ZFS pool, etc.) before
having a forcing requirement. Unallocated free space can be
turned into any of those without further surgery on the
existing partitions.

### Decision 8: New `modules/nixos/server/` baseline

A new module tree at `modules/nixos/server/` captures the
conventions for any headless server. `fedorivns-homelab/`
imports it.

**Rationale:** Establishes the convention without churning
working hosts.

### Decision 9: Lid + power policy on the lab role

The server baseline sets `services.logind.lidSwitch = "ignore"`,
disables sleep-on-AC, and (optionally) raises the laptop's
battery charge threshold so the built-in battery acts as a
small UPS without aging prematurely.

**Rationale:** A laptop with the lid closed will suspend by
default; the homelab must stay running. The battery doubles as
a built-in UPS — a bonus over a typical small server.

## Risks / Trade-offs

- **Disk shrink corruption** → Take a full image backup of the
  current LUKS root to external storage before shrinking. Verify
  the existing install still boots before creating the new
  `homelab-root` partition. Treat the live-USB session as the
  atomic operation; do not reboot mid-shrink.
- **TPM2 PCR sealing breaks on firmware/kernel updates** →
  Document the recovery path (passphrase fallback). Pin a
  conservative PCR set; reseal after kernel updates if needed.
  Acceptable for a homelab in a known physical location.
- ~~**Bootloader default-entry flap on activation**~~ → Resolved
  by Decision 5's flip to per-host ESPs. Each host's
  `loader.conf` is on its own ESP; nothing to race.
- **Second ESP carve-out reclaims `p3` (the thinkpad's
  encrypted swap).** Thinkpad loses hibernation capability;
  acceptable for a yearly-use experimental role on 14 GiB RAM.
  A swapfile on the LUKS-encrypted thinkpad root is a trivial
  add-back if ever needed. The thinkpad host config's
  `swapDevices` stanza must be removed in the same change that
  deletes the partition (see tasks.md section 11.4).
- **UEFI firmware reordering NVRAM entries on firmware update.**
  Once each host has its own UEFI boot entry, a firmware update
  could in principle reorder them. Mitigated by the fact that
  this ThinkPad's firmware has been stable and `efibootmgr -o`
  re-pins the order in seconds if needed. Acceptable cost given
  the shared-ESP failure modes the flip eliminates.
- ~~**Static-DHCP IP drift**~~ → Mitigated by using Avahi/mDNS
  (`fedorivns-homelab.local`) instead of a pinned IP. No router
  reservation needed; mDNS resolves as long as the host is on
  the same LAN.
- **One-year desktop boot causes brief homelab outage** →
  Accepted by the proposal; user explicitly OK with this
  cadence.
- **First-time TPM2 enrollment requires a live session with
  the LUKS volume unlocked** → Documented as a one-time manual
  step in `tasks.md`, not a `nixos-rebuild`-time operation.

## Open Questions

- ~~**Static-DHCP IP value** for the homelab.~~ Resolved: using
  Avahi/mDNS, same as `fedorivns-thinkpad`. `nixos-unified.sshTarget`
  will be `fedorivn@fedorivns-homelab.local`. No router DHCP
  reservation needed.
- **PCR set** for the TPM2 binding. Default
  (`systemd-cryptenroll --tpm2-pcrs=...`) vs. an explicit list.
  Decide during enrollment; document in `tasks.md`.
- **Wake-on-LAN** on the ThinkPad NIC. Convenient for "boot to
  desktop role from MBP" but adds firmware setup. Not in scope;
  flag as a possible follow-up.
- ~~**Identity of partition `/dev/nvme0n1p3`** (15.9G LUKS).~~
  Resolved (2026-06): it's the thinkpad's encrypted swap.
  Deleted entirely as part of section 11 of tasks.md. The
  thinkpad loses hibernation; on a 14 GiB-RAM box used ~yearly
  for experiments, that's acceptable. A swapfile on the
  LUKS-encrypted root is a trivial future add-back if a
  session ever needs one. The new homelab ESP takes 512 MiB
  from the reclaimed space; the remaining ~15.4 GiB is left
  unallocated (consistent with Decision 7).
