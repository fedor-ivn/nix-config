## 1. Create stub flake

- [x] 1.1 Create `secrets-stub/flake.nix` with empty `values` matching the nix-secrets schema (syncthingDevices, knownNetworkServices, clamorPaths, homebrewCasks)
- [x] 1.2 Run `git add secrets-stub/` so Nix can see the new path

## 2. Verify

- [x] 2.1 Run `nix flake check --override-input secrets "path:./secrets-stub"` to confirm the stub is a valid flake
- [x] 2.2 Run a dry eval of one host config with the override to confirm no attribute errors: `nix eval .#nixosConfigurations.fedorivns-thinkpad.config.system.build.toplevel --override-input secrets "path:./secrets-stub"`

## 3. Document

- [x] 3.1 Add a bootstrap section to `README.md` (or create one) with the `--override-input` command for both NixOS and Darwin hosts
