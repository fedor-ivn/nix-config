## 1. Pre-flight (no host changes yet)

- [x] 1.1 Confirm MBP can SSH into the existing `fedorivns-thinkpad`
      and run `just a` against it (rules out unrelated breakage
      before any disk surgery).
- [x] 1.2 ~~Pick the homelab static IP (router DHCP reservation).~~
      Skipped — using Avahi/mDNS (`fedorivns-homelab.local`)
      instead, matching the `fedorivns-thinkpad` setup. No router
      reservation needed.
- [x] 1.3 Decide on a `homelab-root` partition size and a target shrunk
      size for the existing `fedorivns-thinkpad` root.
      - `homelab-root`: **96G**
- [x] 1.4 ~~Take a full image backup of the existing encrypted root
      partition.~~ Skipped — no critical data on this host; not
      worth the time investment.

## 2. Reusable server baseline module

- [x] 2.1 Create `modules/nixos/server/default.nix` with:
      - `services.xserver.enable = false` and no display manager
        imports.
      - `services.openssh.enable = true`,
        `services.openssh.settings.PasswordAuthentication = false`,
        `PermitRootLogin = "no"` (or repo-consistent setting).
      - `services.logind.lidSwitch = "ignore"` plus the
        `lidSwitchExternalPower` / `lidSwitchDocked` variants.
      - `services.timesyncd.enable = true`.
      - `networking.firewall.enable = true` with
        `allowedTCPPorts = [ 22 ]` (host configs extend this).
      - `services.journald.extraConfig` setting a finite
        `SystemMaxUse=` (e.g. `200M`).
      - Power policy disabling auto-suspend on AC (e.g.
        `services.logind.extraConfig` with
        `IdleAction=ignore` and `HandleSuspendKey=ignore`, or
        equivalent NixOS options).
- [x] 2.2 Verify the module is exposed as
      `self.nixosModules.server` via auto-wiring (`nix flake show`).
- [x] 2.3 Build it against a throwaway host (or a `nixosConfigurations`
      smoke entry) to confirm it evaluates cleanly without an
      importing host.

## 3. Homelab flake host scaffolding

- [x] 3.1 Create `configurations/nixos/fedorivns-homelab/default.nix`
      that:
      - Imports `flake.inputs.self.nixosModules.common` (not `default`,
        which pulls in the GUI stack) and
        `flake.inputs.self.nixosModules.server`.
      - Imports `./hardware.nix`.
      - Configures `services.avahi` identically to `fedorivns-thinkpad`
        (enable, nssmdns4, publish addresses) for mDNS discovery.
      - Sets `networking.hostName = "fedorivns-homelab"`.
      - Sets `nixos-unified.sshTarget = "fedorivn@fedorivns-homelab.local"`
        (Avahi mDNS, no static IP needed).
      - Configures `boot.loader.systemd-boot.enable = true`,
        `boot.loader.efi.canTouchEfiVariables = true`,
        `boot.loader.timeout = 3`.
      - Configures the `loader.conf default` to use saved-entry
        semantics via `boot.loader.systemd-boot.extraInstallCommands`
        with a `sed -i '/^default /c\default @saved'` one-liner.
        (`extraConfig` cannot be used here: systemd-boot honors the
        first `default` line; the NixOS-written line always comes
        first, so an appended `extraConfig` line would lose.)
      - Sets `system.stateVersion` to the current channel value.
- [x] 3.2 Add a placeholder `configurations/nixos/fedorivns-homelab/hardware.nix`
      (a single attribute set with a comment noting it will be
      replaced by the live `nixos-generate-config` output during
      install). `git add` so Nix can see it.
- [x] 3.3 Run `nix flake check` on the MBP to confirm the new host
      evaluates (it will fail to *build* without real hardware, but
      should evaluate).

## 4. Disk surgery on the ThinkPad

- [x] 4.1 Boot the ThinkPad from a current NixOS live USB.
- [x] 4.2 Unlock the existing LUKS root, run `fsck` on the
      filesystem, then shrink the filesystem to the size chosen in
      task 1.3 (`resize2fs <size>` or `btrfs filesystem resize`,
      whichever applies).
- [x] 4.3 Shrink the LUKS container with
      `cryptsetup resize --size <sectors>` to match.
- [x] 4.4 Shrink the partition itself (`parted` / `sgdisk`) to match
      the LUKS container.
- [x] 4.5 Create a new partition immediately after the shrunk root
      for `homelab-root` (do not consume the rest of the disk — leave
      the trailing free space unallocated, per Decision 7).
- [x] 4.6 `cryptsetup luksFormat` the new partition (LUKS2). Add a
      strong passphrase keyslot (this is the recovery slot — keep
      it offline). LUKS label: `homelab-root`, partition: `/dev/nvme0n1p4`.
- [x] 4.7 Open the new LUKS volume and create a filesystem on it
      (ext4 or btrfs, matching repo convention).
- [x] 4.8 Reboot the ThinkPad into the existing
      `fedorivns-thinkpad` install. Verify it boots normally
      (smoke test the existing role survived).

## 5. Install NixOS on `homelab-root`

- [x] 5.1 Boot the live USB again. Mount the new `homelab-root` at
      `/mnt`, the shared ESP at `/mnt/boot`. Confirm the ESP
      mounted is the *same* ESP used by `fedorivns-thinkpad`.
- [x] 5.2 Run `nixos-generate-config --root /mnt --no-filesystems`
      (or with filesystems if preferred) and copy the generated
      `hardware-configuration.nix` into the repo's
      `configurations/nixos/fedorivns-homelab/hardware.nix`,
      replacing the placeholder from task 3.2. Adjust file paths
      so it imports cleanly within the repo (mirror the existing
      `fedorivns-thinkpad/hardware.nix` pattern).
- [x] 5.3 Ensure the generated config declares the LUKS device for
      `homelab-root` (`boot.initrd.luks.devices.<name>`).
- [x] 5.4 Place the personal age key at
      `~/.config/sops/age/keys.txt` on the live USB environment
      (export it from your password manager). Then run
      `nixos-install --flake <repo>#fedorivns-homelab`.
- [x] 5.5 Reboot. Verify the `systemd-boot` menu now lists both
      `fedorivns-thinkpad` and `fedorivns-homelab` entries.
- [x] 5.6 Select the homelab entry and confirm it boots, networks,
      and is reachable over SSH from the MBP.

## 6. SOPS / age recipient for the new host

~~Skipped — single personal age key model: no per-host SSH recipient needed.
The homelab decrypts secrets using the personal age key placed at install
time (task 5.4). `.sops.yaml` was updated in commit 715da0f.~~

## 7. TPM2 unattended unlock

- [x] 7.1 On the homelab, verify TPM2 hardware availability:
      `systemd-cryptenroll --tpm2-device=list` shows the chip.
- [x] 7.2 Enroll the TPM2 key into the `homelab-root` LUKS device:
      `systemd-cryptenroll /dev/<homelab-root-part>
      --tpm2-device=auto --tpm2-pcrs=<chosen PCRs>`. Document the
      PCR set used (record in this change or as a comment in the
      host config).
- [x] 7.3 Update `configurations/nixos/fedorivns-homelab/hardware.nix`
      (or `default.nix`) so the LUKS device specifies
      `crypttabExtraOpts = [ "tpm2-device=auto" ]` (or the
      equivalent NixOS option) for the homelab-root entry.
- [x] 7.4 Reboot with no keyboard attached. Confirm the homelab
      reaches the login prompt and is reachable over SSH without
      any LUKS prompt interaction.
- [x] 7.5 Verify the passphrase keyslot still unlocks the volume
      manually (sanity-check the fallback): boot the live USB
      and `cryptsetup open` with the passphrase.

## 8. Bootloader default + timeout verification

- [x] 8.1 Confirm `loader.conf` on the shared ESP contains
      `default @saved` (or the equivalent) after activation.
- [ ] 8.2 Reboot, pick the homelab entry from the menu, reboot
      again with no input → homelab is the default-highlighted
      entry.
- [ ] 8.3 Reboot, pick the desktop entry from the menu, reboot
      again with no input → desktop is the default-highlighted
      entry (saved-entry persistence works).
- [ ] 8.4 Reboot once more and pick homelab to restore the
      everyday default.

## 9. Networking verification

- [x] 9.1 ~~Add a DHCP reservation on the router.~~ Skipped — Avahi
      handles discovery; no static IP or reservation needed.
- [x] 9.2 Confirm `nixos-unified.sshTarget = "fedorivn@fedorivns-homelab.local"`
      resolves on the MBP and `just a` deploys succeed.

## 10. Acceptance pass

- [ ] 10.1 Run through every scenario in
      `specs/homelab-host/spec.md` and confirm each behaves as
      specified. Mark any deviations as follow-up issues, not
      blockers.
- [ ] 10.2 Run through every scenario in
      `specs/server-baseline/spec.md` likewise.
- [ ] 10.3 Power-cycle the ThinkPad (cold boot) with no keyboard
      attached and confirm the homelab reaches an SSH-reachable
      state unattended.
- [ ] 10.4 Boot into the desktop role once, confirm it still
      activates with `just a`, then return to the homelab as
      default.
- [ ] 10.5 Run `openspec validate add-fedorivns-homelab` (or the
      repo's equivalent) and confirm no errors.

## 11. Migrate from shared ESP to per-host ESPs (revised Decision 5)

Background: sections 4–5 built a shared-ESP setup with
`extraInstallCommands` renaming each host's entries to avoid
collision. In practice this hit three failure modes (see
`design.md` Decision 5, revised). This section migrates to the
two-ESP layout. Thinkpad keeps the original ESP
(`/dev/nvme0n1p1`); homelab moves to a new ESP carved out below.

### 11.1 Reclaim `p3` (thinkpad swap)

`/dev/nvme0n1p3` is the thinkpad's encrypted swap (LUKS,
15.9 GiB, inner swap UUID `205cca1f-7ab3-4852-b731-056ffdeca9c8`
referenced from `configurations/nixos/fedorivns-thinkpad/hardware.nix`).
Decision (2026-06): delete it entirely. The thinkpad's yearly-use
experimental role does not need swap on 14 GiB of RAM; the homelab
already runs swap-free. The new homelab ESP takes ~512 MiB from
the reclaimed space; the remaining ~15.4 GiB is left unallocated.

- [ ] 11.1.1 Confirm the thinkpad role is not booted and
      nothing is using `p3` (homelab's `/proc/swaps` is empty
      and `swapDevices = [ ]`; the LUKS swap is only ever
      opened by the thinkpad).

### 11.2 Create the new ESP

- [ ] 11.2.1 Boot the ThinkPad from a current NixOS live USB.
- [ ] 11.2.2 `wipefs -a /dev/nvme0n1p3` to clear the LUKS
      signature on the old swap.
- [ ] 11.2.3 Use `parted` / `sgdisk` to delete `p3` and create
      a new 512 MiB partition at the start of the reclaimed
      space, type `EF00`. Leave the trailing ~15.4 GiB
      unallocated. Reuse partition number `3` (the slot is
      free — no renumbering of `p4` needed).
- [ ] 11.2.4 `mkfs.vfat -F32 -n HOMELAB-ESP /dev/nvme0n1p3`.
      Record the new ESP's filesystem UUID
      (`blkid /dev/nvme0n1p3`).
- [ ] 11.2.5 Set ESP/boot flags
      (`parted /dev/nvme0n1 set 3 esp on`,
      `parted /dev/nvme0n1 set 3 boot on`).

### 11.3 Install the homelab bootloader on the new ESP

- [ ] 11.3.1 Update
      `configurations/nixos/fedorivns-homelab/hardware.nix`:
      replace the `/boot` UUID with the new ESP's UUID.
- [ ] 11.3.2 Remove the `extraInstallCommands` block from
      `configurations/nixos/fedorivns-homelab/default.nix`,
      leaving the systemd-boot config as the vanilla
      `boot.loader.systemd-boot.enable = true;`,
      `boot.loader.efi.canTouchEfiVariables = true;`,
      `boot.loader.timeout = 3;` only.
- [ ] 11.3.3 Boot the homelab normally from the existing shared
      ESP one last time. Then, from inside the running homelab,
      unmount `/boot` (`sudo umount /boot`), mount the new ESP
      at `/boot` (`sudo mount /dev/nvme0n1p3 /boot`), and run
      `just a homelab` (or `nix run .#activate fedorivns-homelab`).
      NixOS will install `systemd-boot` into the newly-mounted
      ESP and register a new UEFI firmware boot entry pointing at
      it (because `canTouchEfiVariables = true`).
- [ ] 11.3.4 Verify the new ESP contains exactly one entry:
      `ls /boot/loader/entries/` should show one
      `nixos-generation-N.conf` — no homelab/thinkpad prefixes,
      no orphans.

### 11.4 Clean up the old (now thinkpad-only) ESP

- [ ] 11.4.1 Edit the thinkpad host config (do not activate
      yet):
      - `configurations/nixos/fedorivns-thinkpad/hardware.nix`:
        remove the `swapDevices` stanza (the backing partition
        is gone after section 11.2).
      - `configurations/nixos/fedorivns-thinkpad/default.nix`:
        remove the `extraInstallCommands` block, leaving
        vanilla systemd-boot config only.
- [ ] 11.4.2 From the homelab (or a live USB), mount the old
      ESP (`/dev/nvme0n1p1`) read-write at a temp path. Delete
      all `homelab-*.conf` entries and any orphan
      `nixos-generation-*.conf` files. Delete any `/EFI/nixos/`
      stubs that are no longer referenced by remaining
      thinkpad entries (cross-check by `grep`-ing the entry
      files for stub paths).
- [ ] 11.4.3 Verify the old ESP's `loader.conf` reads
      `default @saved` (or remove the `default` line entirely
      so systemd-boot picks the highest-versioned thinkpad
      entry automatically — the `extraInstallCommands` removal
      means subsequent `just a thinkpad` will rewrite
      `loader.conf` to NixOS's vanilla form anyway).

### 11.5 Set UEFI boot order

- [ ] 11.5.1 Run `sudo efibootmgr -v` and identify the boot IDs
      for the two ESPs. Record both. (Install `efibootmgr` via
      a one-off `nix shell` if needed.)
- [ ] 11.5.2 Set the persistent order so the homelab ESP is
      default: `sudo efibootmgr -o <homelab-id>,<thinkpad-id>`.
- [ ] 11.5.3 Document the one-shot "boot into desktop next time
      only" command in `design.md` Decision 5 or a follow-up
      ops note: `sudo efibootmgr -n <thinkpad-id> && sudo reboot`.

### 11.6 Verification

- [ ] 11.6.1 Cold-boot the ThinkPad (power off, power on, no
      keyboard). It should land in the homelab role
      automatically, TPM2 should unlock `homelab-root`, and
      SSH should be reachable.
- [ ] 11.6.2 Run `just a homelab` from the MBP. Confirm the
      activation writes only to the homelab's own ESP
      (`/dev/nvme0n1pN` mounted at `/boot`) and that no
      `extraInstallCommands` step appears in the activation
      output.
- [ ] 11.6.3 One-shot reboot into thinkpad:
      `sudo efibootmgr -n <thinkpad-id> && sudo reboot` from
      the homelab over SSH. Confirm the thinkpad desktop boots
      from its own (now exclusive) ESP and that it presents the
      passphrase prompt for the thinkpad LUKS root (unchanged).
- [ ] 11.6.4 Run `just a thinkpad` from the MBP while the
      desktop is up. Confirm activation writes only to
      `/dev/nvme0n1p1` and that NixOS rewrites `loader.conf` to
      its vanilla form.
- [ ] 11.6.5 Reboot once more without `-n`. Confirm the default
      order from 11.5.2 is restored and the homelab is the
      power-on default again.
- [ ] 11.6.6 Confirm there is no `nixos-generation-*.conf`
      orphan on either ESP.

## 12. Archive

- [ ] 12.1 When all tasks above are checked off and the homelab
      has run unattended for at least one week without
      intervention, run `/opsx:archive` (or `openspec archive
      add-fedorivns-homelab`) to move the change into the
      archived set.
