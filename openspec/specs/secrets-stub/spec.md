# Spec: secrets-stub

## Purpose

A stub flake (`secrets-stub/`) that satisfies the `nix-secrets` input interface with safe empty defaults, enabling bootstrap builds on machines that lack SSH credentials to the private `nix-secrets` repository.

## Requirements

### Requirement: Stub flake provides empty values matching the nix-secrets schema
The stub flake at `secrets-stub/flake.nix` SHALL export a `values` attribute with the same top-level keys as `nix-secrets` filled with empty defaults (empty lists, empty attrsets, empty strings), so that all existing consumers evaluate without error.

#### Scenario: List consumers receive empty list
- **WHEN** a module concatenates `++ secrets.knownNetworkServices` or `++ secrets.homebrewCasks` with the stub active
- **THEN** the concatenation produces the same result as if the attribute were `[]`

#### Scenario: Attrset consumers receive empty attrset
- **WHEN** a module calls `lib.mapAttrs` over `secrets.clamorPaths` with the stub active
- **THEN** the result is an empty attrset and no evaluation error occurs

#### Scenario: String consumers receive empty string
- **WHEN** a module accesses `secrets.syncthingDevices.fedorivns-iphone` or `secrets.syncthingDevices.fedorivns-mbp` with the stub active
- **THEN** the attribute evaluates to `""` without error

### Requirement: Bootstrap build succeeds with --override-input
A fresh machine without SSH credentials to `github.com/fedor-ivn/nix-secrets` SHALL be able to build any host configuration by passing `--override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"` to `nixos-rebuild` or `darwin-rebuild`.

#### Scenario: NixOS bootstrap
- **WHEN** user runs `nixos-rebuild switch --flake ".#fedorivns-thinkpad" --override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"`
- **THEN** the build completes without SSH credential errors

#### Scenario: Darwin bootstrap
- **WHEN** user runs `darwin-rebuild switch --flake ".#fedorivns-mbp" --override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"`
- **THEN** the build completes without SSH credential errors
