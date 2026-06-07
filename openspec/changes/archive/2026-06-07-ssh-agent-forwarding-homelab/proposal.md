## Why

When deploying to `fedorivns-homelab`, Nix cannot fetch the private `nix-secrets` flake input (`git+ssh://git@github.com/fedor-ivn/nix-secrets`) because the homelab has no GitHub SSH credentials. Rather than placing a key on disk, we forward the MBP's SSH agent over the existing deploy SSH connection.

## What Changes

- Add `ForwardAgent yes` to `~/.ssh/config` on the MBP for `fedorivns-homelab.local`
- Add `Defaults env_keep+=SSH_AUTH_SOCK` to sudoers on the homelab so `nixos-rebuild switch` (which runs under sudo) inherits the forwarded agent socket
- Add a `homelab` alias to the `Justfile` so `just a homelab` works alongside `just a thinkpad`

## Capabilities

### New Capabilities

- `homelab-deploy`: MBP can deploy to `fedorivns-homelab` via `just a homelab` with agent forwarding, enabling Nix to fetch the private `nix-secrets` flake input without any key material on the homelab disk

### Modified Capabilities

<!-- none -->

## Impact

- `Justfile` — new `homelab` alias in the `activate` recipe
- MBP SSH config (`~/.ssh/config` managed by nix-darwin / home-manager) — `ForwardAgent yes` for homelab host
- `configurations/nixos/fedorivns-homelab/default.nix` — sudoers `env_keep` for `SSH_AUTH_SOCK`
