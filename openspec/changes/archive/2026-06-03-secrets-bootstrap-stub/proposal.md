## Why

Bootstrapping a new machine fails because Nix eagerly fetches all flake inputs, including the private `nix-secrets` flake (`git+ssh://git@github.com/fedor-ivn/nix-secrets`), which requires SSH credentials. On a fresh machine, SSH keys aren't set up yet — creating a chicken-and-egg problem.

## What Changes

- Add `secrets-stub/flake.nix` to this repo — a public flake with the same `values` schema as `nix-secrets` but empty/default values
- Document the bootstrap override command in `README.md`

## Capabilities

### New Capabilities

- `secrets-stub`: A colocated public stub flake (`github:fedor-ivn/nix-config?dir=secrets-stub`) that satisfies the `inputs.secrets` schema with empty defaults, enabling bootstrap builds via `--override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"`

### Modified Capabilities

## Impact

- New file: `secrets-stub/flake.nix`
- No changes to existing modules or configurations
- No changes to `flake.nix` itself — override is passed at build time
