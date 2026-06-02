## 1. Client-side: Ghostty HM settings

- [x] 1.1 Add `shell-integration-features = "ssh-env,ssh-terminfo"` to `programs.ghostty.settings` in `modules/home/ghostty.nix`

## 2. Server-side: NixOS system packages

- [x] 2.1 Add `pkgs.ghostty.terminfo` to `environment.systemPackages` in `modules/nixos/common/default.nix`

## 3. Shell alias fallback

- [x] 3.1 ~~Add `ssh = "ghostty +ssh"` to `home.shellAliases` in `modules/home/shell.nix`~~ — removed, `ghostty +ssh` is not a valid action; shell integration covers this
