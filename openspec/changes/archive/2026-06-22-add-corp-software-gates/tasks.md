## 1. Shared modules — remove personal packages

- [x] 1.1 Remove `vlc` from `linuxOnlyGuiApps` in `modules/home/packages.nix`
- [x] 1.2 Remove `zoom-us` from `baseGuiApps` in `modules/home/packages.nix`
- [x] 1.3 Remove `iina` from `darwinOnlyGuiApps` in `modules/home/packages.nix`
- [x] 1.4 Remove `chatgpt`, `claude`, `altserver` from the cask list in `modules/darwin/homebrew.nix`

## 2. Shared modules — enable option changes

- [x] 2.1 Add `options.programs.whisply.enable = lib.mkEnableOption "whisply" // { default = true; }` to `modules/home/whisply.nix` and wrap the existing `mkIf isDarwin` block so both conditions apply
- [x] 2.2 Change `programs.codex.enable = true` to `programs.codex.enable = lib.mkDefault true` in `modules/home/codex.nix`

## 3. MBP host config — add personal packages and casks

- [x] 3.1 Add `home-manager.users.fedorivn.home.packages = with pkgs; [ iina zoom-us ];` to `configurations/darwin/fedorivns-mbp/default.nix`
- [x] 3.2 Add `chatgpt`, `claude`, `altserver` to `homebrew.casks` in `configurations/darwin/fedorivns-mbp/default.nix` (using `{ name = "..."; greedy = true; }` form to match the shared module style)

## 4. ThinkPad host config — add vlc

- [x] 4.1 Add `home-manager.users.fedorivn.home.packages = with pkgs; [ vlc ];` to `configurations/nixos/fedorivns-thinkpad/default.nix`

## 5. Verify

- [x] 5.1 Build MBP config (`nix build .#darwinConfigurations.fedorivns-mbp.system`) and confirm no eval errors
- [x] 5.2 Activate on MBP (`just a`) and confirm iina, zoom-us, chatgpt, claude, altserver are still present
- [x] 5.3 Confirm whisply still works on MBP post-activation
