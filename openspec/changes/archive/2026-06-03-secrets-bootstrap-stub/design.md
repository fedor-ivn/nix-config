## Context

The `nix-secrets` flake (`git+ssh://git@github.com/fedor-ivn/nix-secrets`) is a private SSH-gated flake providing eval-time values via `flake.inputs.secrets.values`. Nix fetches all flake inputs eagerly — even inputs unused by a specific host config. On a fresh machine without SSH credentials, `nixos-rebuild` or `darwin-rebuild` fails before any Nix evaluation occurs.

Current `values` schema consumed by the config:
```
secrets.syncthingDevices.fedorivns-iphone  # string — syncthing device ID
secrets.syncthingDevices.fedorivns-mbp     # string — syncthing device ID
secrets.knownNetworkServices               # list of strings
secrets.clamorPaths                        # attrset of strings (name → path)
secrets.homebrewCasks                      # list of strings
```

## Goals / Non-Goals

**Goals:**
- Allow bootstrapping any host config on a machine without SSH credentials
- Require zero changes to `flake.nix`, existing modules, or host configs
- Keep the stub colocated in this repo (no separate repository to maintain)

**Non-Goals:**
- Making secrets truly optional at the module level (NixOS module option guards)
- Removing the private secrets flake dependency permanently
- Handling runtime sops secrets (different mechanism, different problem)

## Decisions

### Use `--override-input` at build time, not a default change in `flake.nix`

`flake.nix` stays unchanged. The override is a caller-side flag:
```
--override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"
```

**Why**: Changing `flake.nix` default URL to the stub would require machines with real secrets to always pass `--override-input` the other direction. The current default (real secrets) is the common case.

Alternative considered: make `flake.nix` default to the stub and let machines with credentials override. Rejected — every normal build would need an extra flag.

### Stub lives in `secrets-stub/` within this repo

`github:fedor-ivn/nix-config?dir=secrets-stub` is the override URL. No second repository.

**Why**: Schema stays colocated with its consumers. When a new value is added to `nix-secrets`, the stub in the same PR is the natural reminder to update it.

### Empty/zero defaults (not error-throwing stubs)

- Lists → `[]`
- Attrsets → `{}`
- Strings → `""`

All current consumers handle these gracefully:
- `++ secrets.knownNetworkServices` → appends nothing
- `++ secrets.homebrewCasks` → appends nothing
- `lib.mapAttrs ... secrets.clamorPaths` → maps empty attrset → empty
- `secrets.syncthingDevices.*` → evaluates to `""` but `services.syncthing.enable = false` so irrelevant at activation time

## Risks / Trade-offs

- **Schema drift** → If `nix-secrets` adds a new attribute and a consumer accesses it without null-checking, a bootstrap build will throw an eval error. Mitigation: the stub is in-repo, so the PR that adds a new consumer should also update the stub.
- **Stub URL tied to `master`** → `github:fedor-ivn/nix-config?dir=secrets-stub` always fetches latest master. A broken stub on master breaks bootstrapping. Low risk for a personal config.
