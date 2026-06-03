## 1. Manual One-Time Cleanup (on ThinkPad)

- [x] 1.1 Run `sudo nix-collect-garbage --delete-older-than 7d` to purge old system generations
- [x] 1.2 Clear heavy caches: `rm -rf ~/.cache/{pypoetry,mix,pyright-python,evision-nif*,mozilla,thumbnails}`
- [x] 1.3 Clean Rust build artifacts: `cargo clean` in `~/projects/natively-cluely-ai-assistant/native-module` and `~/projects/interview`
- [x] 1.4 Clean Elixir build artifacts: `mix clean` in `~/projects/vamper` and `~/projects/blockscout` (if inactive)
- [x] 1.5 Verify freed space with `df -h /` and `du -sh /nix/store`

## 2. Config: Package Restructuring

- [x] 2.1 Remove `hoppscotch` from the `base` list in `modules/home/packages.nix`
- [x] 2.2 Comment out `slack`, `zoom-us`, `qbittorrent` in `base` (tmp disable on ThinkPad)
- [x] 2.3 Comment out `libreoffice`, `ungoogled-chromium` in `linuxOnly` (tmp disable on ThinkPad)
- [x] 2.4 (n/a — simpler comment-based approach used instead of thinkpadOnly list)

## 3. Config: Automatic GC on ThinkPad System

- [x] 3.1 Add `nix.gc` config to `configurations/nixos/fedorivns-thinkpad/default.nix` with `automatic = true` and `options = "--delete-older-than 7d"`

## 4. Validate

- [x] 4.1 Run `just a` on ThinkPad, confirm build succeeds with no eval errors
- [x] 4.2 Verify `slack`, `zoom-us`, `qbittorrent`, `libreoffice`, `ungoogled-chromium` present in ThinkPad profile
- [x] 4.3 Verify `hoppscotch` absent from ThinkPad profile
- [x] 4.4 Run `nix eval .#homeConfigurations."fedorivn@fedorivns-mbp".config.home.packages` (or dry-activate on MBP) to confirm none of the moved packages leak into macOS
