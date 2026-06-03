# nix-config

Personal NixOS + macOS (nix-darwin) configuration managed as a flake, using
[nixos-unified](https://nixos-unified.org) for auto-wiring and
[flake-parts](https://flake.parts) for output composition.

## Hosts

| Hostname | Platform | Notes |
|---|---|---|
| `fedorivns-thinkpad` | x86_64-linux (NixOS) | primary Linux machine |
| `fedorivns-mbp` | aarch64-darwin (macOS) | MacBook Pro |
| `fedorivns-vps` | x86_64-linux (NixOS) | VPS |

## Layout

```
configurations/
  darwin/<hostname>/   # nix-darwin system configs
  nixos/<hostname>/    # NixOS system configs
  home/<username>.nix  # Home Manager user configs
modules/
  darwin/              # macOS-specific modules (Aerospace WM, Homebrew, …)
  home/                # shared Home Manager modules
  nixos/               # shared NixOS modules
  flake/               # flake-parts modules (devshell, formatter, …)
```

## Usage

Requires [Nix](https://nixos.org/download/) with flakes enabled.
Enter the dev shell first to get `just`:

```sh
nix develop
just          # list available commands
just activate # apply the configuration (nix run .#activate)
just update   # update all flake inputs
just lint     # format Nix files
just check    # validate the flake
```

## Secrets

- **`secrets.yaml`** — SOPS-encrypted, decrypted at activation by
  [sops-nix](https://github.com/Mic92/sops-nix). Age key expected at
  `~/.config/sops/age/keys.txt`.
- **`inputs.secrets`** — evaluation-time secrets in a private flake
  (`fedor-ivn/nix-secrets`); access is controlled by SSH key.

## Bootstrapping a new machine

On a fresh machine without SSH credentials, Nix will fail to fetch the private
`nix-secrets` flake. Use the colocated stub to bypass it:

```sh
# NixOS
nixos-rebuild switch --flake ".#fedorivns-thinkpad" \
  --override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"

# macOS
darwin-rebuild switch --flake ".#fedorivns-mbp" \
  --override-input secrets "github:fedor-ivn/nix-config?dir=secrets-stub"
```

The stub (`secrets-stub/flake.nix`) provides empty defaults for all
`inputs.secrets.values` attributes. Once SSH credentials are set up, rebuild
normally without the override.
