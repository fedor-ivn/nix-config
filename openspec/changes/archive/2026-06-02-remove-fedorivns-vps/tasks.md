## 1. Remove VPS host configuration

- [x] 1.1 Delete `configurations/nixos/fedorivns-vps/` and its contents.
- [x] 1.2 Run `nix flake show` and confirm `fedorivns-vps` no longer appears
      under `nixosConfigurations`.
- [x] 1.3 Run `nix flake check` and confirm it completes successfully.

## 2. Remove vps-lima SSH alias

- [x] 2.1 Delete the `vps-lima` host block from `modules/home/ssh.nix`
      (hostname `127.0.0.1`, port `53555`, user `root`).
- [x] 2.2 Activate home-manager on the MBP (`just a` or `home-manager switch`) ✓ ~/.ssh/config empty
      and confirm `~/.ssh/config` no longer contains a `Host vps-lima` block.

## 3. Update add-fedorivns-homelab change docs

- [x] 3.1 In `openspec/changes/add-fedorivns-homelab/design.md`:
      - Remove `fedorivns-vps` from the "Context" host list.
      - Remove the "Drift between fedorivns-homelab and fedorivns-vps" risk entry.
      - Remove the "Migrating fedorivns-vps onto server-baseline" non-goal entry.
- [x] 3.2 In `openspec/changes/add-fedorivns-homelab/proposal.md`:
      - Remove the `fedorivns-vps: untouched` bullet from the Impact section.

## 4. Archive

- [x] 4.1 Commit all deletions and doc updates in a single commit.
- [ ] 4.2 Run `/opsx:archive` (or `openspec archive remove-fedorivns-vps`) to
      move this change into the archived set.
