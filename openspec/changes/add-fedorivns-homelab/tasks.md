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

- [ ] 7.1 On the homelab, verify TPM2 hardware availability:
      `systemd-cryptenroll --tpm2-device=list` shows the chip.
- [ ] 7.2 Enroll the TPM2 key into the `homelab-root` LUKS device:
      `systemd-cryptenroll /dev/<homelab-root-part>
      --tpm2-device=auto --tpm2-pcrs=<chosen PCRs>`. Document the
      PCR set used (record in this change or as a comment in the
      host config).
- [ ] 7.3 Update `configurations/nixos/fedorivns-homelab/hardware.nix`
      (or `default.nix`) so the LUKS device specifies
      `crypttabExtraOpts = [ "tpm2-device=auto" ]` (or the
      equivalent NixOS option) for the homelab-root entry.
- [ ] 7.4 Reboot with no keyboard attached. Confirm the homelab
      reaches the login prompt and is reachable over SSH without
      any LUKS prompt interaction.
- [ ] 7.5 Verify the passphrase keyslot still unlocks the volume
      manually (sanity-check the fallback): boot the live USB
      and `cryptsetup open` with the passphrase.

## 8. Bootloader default + timeout verification

- [ ] 8.1 Confirm `loader.conf` on the shared ESP contains
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
- [ ] 9.2 Confirm `nixos-unified.sshTarget = "fedorivn@fedorivns-homelab.local"`
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

## 11. Archive

- [ ] 11.1 When all tasks above are checked off and the homelab
      has run unattended for at least one week without
      intervention, run `/opsx:archive` (or `openspec archive
      add-fedorivns-homelab`) to move the change into the
      archived set.
