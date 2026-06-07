## 1. Homelab NixOS config — sudoers env_keep

- [x] 1.1 Add `security.sudo.extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";` to `configurations/nixos/fedorivns-homelab/default.nix`
- [ ] 1.2 Deploy to homelab (`just a homelab` — may fail on nix-secrets fetch, that's expected; verify the sudoers line lands in `/etc/sudoers.d/`)

## 2. MBP SSH config — agent forwarding

- [x] 2.1 Add a `fedorivns-homelab.local` match block with `forwardAgent = true` to the MBP's home-manager SSH config (locate `programs.ssh.matchBlocks` in the MBP darwin/home config)
- [ ] 2.2 Activate on MBP (`just a`) and verify `~/.ssh/config` contains `ForwardAgent yes` for `fedorivns-homelab.local`

## 3. Justfile — homelab alias

- [x] 3.1 Add `homelab` as a recognized alias in the `activate` recipe (maps to `fedorivns-homelab`), mirroring the existing `thinkpad` alias

## 4. End-to-end verification

- [ ] 4.1 Run `just a homelab` from the MBP; confirm the deploy completes successfully (nix-secrets fetched, system activated)
- [ ] 4.2 On the homelab, run `sudo env | grep SSH_AUTH_SOCK` during an active SSH session from MBP to confirm the socket is preserved under sudo
