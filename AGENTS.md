# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Use `just` (available in the dev shell) to run common tasks:

```sh
just          # list available commands
just run      # activate the configuration (nix run)
just update   # update flake inputs (nix flake update)
just lint     # format nix files (nix fmt → nixpkgs-fmt)
just check    # validate the flake (nix flake check)
just dev      # enter the dev shell (provides just + nixd)
```

## Architecture

This is a **NixOS + Home Manager** configuration managed as a flake, using
[nixos-unified](https://nixos-unified.org) for auto-wiring and [flake-parts](https://flake.parts) for flake
output composition.

### Auto-wiring convention

`nixos-unified` automatically discovers and wires modules by directory:
- `configurations/nixos/<hostname>/` → NixOS system configuration for that host
- `configurations/darwin/<hostname>/` → macOS (nix-darwin) system configuration for that host
- `configurations/home/<username>.nix` → Home Manager configuration for that user
- `modules/nixos/` → reusable NixOS modules (exported as `self.nixosModules.*`)
- `modules/darwin/` → reusable nix-darwin modules (exported as `self.darwinModules.*`)
- `modules/home/` → reusable Home Manager modules (exported as `self.homeModules.*`)
- `modules/flake/` → flake-parts modules (devshell, toplevel glue, neovim package)

`default.nix` files inside `modules/home/` auto-import all sibling `.nix` files in their directory.
`modules/nixos/default.nix` and `modules/darwin/default.nix` explicitly import named sub-modules.

**Darwin internals:** autoWire wraps each `configurations/darwin/*/default.nix` with
`self.nixos-unified.lib.mkMacosSystem { home-manager = true; }`, which calls
`nix-darwin.lib.darwinSystem` and injects `home-manager.darwinModules.home-manager` automatically.
Special args passed to all Darwin (and home-manager) modules: `flake = { self, inputs, config; }` and
`rosettaPkgs`. Access extra flake inputs via `flake.inputs.<name>` — no manual specialArgs needed.

**Shared user management:** `modules/nixos/common/users.nix` is platform-aware and can be imported
from Darwin modules too — it sets `users.users.*` (with `/Users/` home on Darwin) and
`home-manager.users.*` by auto-discovering usernames from `configurations/home/*.nix`.

### Key files

| File | Purpose |
|---|---|
| `flake.nix` | Entry point; delegates everything to `nixos-unified.lib.mkFlake` |
| `modules/flake/toplevel.nix` | Sets formatter (`nixpkgs-fmt`) and `packages.default = activate` |
| `modules/flake/devshell.nix` | Dev shell with `just` + `nixd` |
| `modules/flake/neovim.nix` | Standalone `packages.neovim` built via nixvim |
| `modules/home/me.nix` | Defines the `me.*` options (username, fullname, email) used across modules |
| `configurations/home/fedorivn.nix` | Per-user home config; sets `me.*`, sops, and stateVersion |
| `configurations/nixos/fedorivns-thinkpad/` | ThinkPad NixOS host; sets boot, LUKS, networking, syncthing |
| `configurations/darwin/fedorivns-mbp/` | MacBook Pro Darwin host (aarch64-darwin) — planned |
| `modules/nixos/common/` | Shared NixOS/Darwin settings: user management, networking, tailscale, docker, zsh |
| `modules/nixos/gui/` | GUI stack: X11 + KDE Plasma |
| `modules/darwin/` | macOS system defaults, Aerospace WM, Homebrew casks — planned |

### Hosts

| Host | Platform | Config location |
|---|---|---|
| `fedorivns-thinkpad` | x86_64-linux (NixOS) | `configurations/nixos/fedorivns-thinkpad/` |
| `fedorivns-mbp` | aarch64-darwin (macOS) | `configurations/darwin/fedorivns-mbp/` — planned |

### Secrets

Two secrets sources are in use:

- **`secrets.yaml`** — SOPS-encrypted YAML, managed by `sops-nix`; decrypted at activation time by
  the sops-nix module. Contains taskwarrior sync credentials. The age key is expected at
  `~/.config/sops/age/keys.txt`.

- **`inputs.secrets` (private flake)** — Nix evaluation-time secrets (e.g. `homebrewCasks`,
  `knownNetworkServices`) stored in the private `fedor-ivn/nix-secrets` GitHub repo and
  referenced as a flake input:
  ```nix
  secrets.url = "git+ssh://git@github.com/fedor-ivn/nix-secrets";
  ```
  Local checkout: `~/projects/nix-secrets/`. Consumed via `flake.inputs.secrets.secrets`.
  No decryption step needed — access is controlled by SSH key / repo visibility.

The `secrets.yaml` age key (`age1tekqv95z...`) is configured in `.sops.yaml`.

### Cross-platform packages

`modules/home/packages.nix` splits packages into `base`, `linuxOnly`, and `darwinOnly` lists and conditionally
includes them using `pkgs.stdenv.hostPlatform.isLinux` / `isDarwin`.

## Common Gotchas

- **Untracked files are invisible to Nix** — always `git add` new files before building, or Nix may silently ignore them.
- **Home Manager host-specific toggles** — prefer `config.me.isMainMachine` for machine-specific HM settings instead of platform checks like `pkgs.stdenv.hostPlatform.isDarwin`.
- **Disable RTK temporarily** — set `RTK_DISABLED=1` to bypass the PreToolUse rewrite when debugging weird tool output or RTK miscompression.
