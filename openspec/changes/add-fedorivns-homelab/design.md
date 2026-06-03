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

### Decision 5: Single shared ESP, `default = @saved`

Both NixOS installs use `systemd-boot` against one shared ESP
partition. `boot.loader.timeout = 3`. `loader.conf` is configured
with `default = @saved` (or the equivalent NixOS option) so
`systemd-boot` remembers the last selected entry.

**Rationale:** `systemd-boot` namespaces entry filenames per
install (each NixOS has its own machine-id), so menu entries do
not collide. The `loader.conf default` pointer does collide —
whichever host was activated last wins. `@saved` neutralizes
that: the last *boot* choice persists across activations.
Operationally: after `just a` on either host, the next reboot
goes to whichever entry was last picked from the menu, not the
host that was just rebuilt.

**Alternatives considered:**

- *Two separate ESPs.* Cleanest isolation; firmware boot order
  picks which ESP to chainload. Cost: an extra partition, extra
  fragility on firmware updates that reorder UEFI entries. Not
  worth it for a two-install setup.
- *Accept the flap (no `@saved`).* Reasonable, but easy to
  forget: a stray `just a` on the desktop role silently makes
  desktop the default. `@saved` is a one-line fix.

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

### Decision 7: Leave free space unallocated

After shrinking the existing root and creating the new
`homelab-root` LUKS partition, the remaining disk space is left
unallocated.

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
- **Bootloader default-entry flap on activation** → Mitigated
  with `default = @saved`; user picks the entry once at boot
  and it sticks.
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
