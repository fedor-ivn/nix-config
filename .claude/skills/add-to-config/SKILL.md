---
name: add-to-config
description: Add a tool or configure something new in the nix-config. Triggers on phrases like "add package", "enable service", or "configure nix".
user-invokable: true
---

# add-to-config

Guide for adding packages and programs to this NixOS + nix-darwin flake.

## Searching for a package

Before adding anything, confirm the package name AND check for a Home Manager module:

1. **MyNixOS — CHECK FIRST** — https://mynixos.com/home-manager/options/programs.<name> — **ALWAYS check this before anything else.** If `programs.<name>` exists, you MUST use it instead of adding to `home.packages`. NEVER add a bare package when a `programs.*` module is available.
2. **NixOS Search** — https://search.nixos.org/packages — search by name; shows the attribute path (e.g. `pkgs.ripgrep`), available platforms.
3. **Homebrew Cask Search** (macOS-only packages) — https://formulae.brew.sh/cask/ — for GUI apps not available or broken in nixpkgs on Darwin.
4. **In-repo check** — `Grep` for the package name across `modules/` to see if it's already installed or partially configured.

---

## Decision tree

**MANDATORY FIRST STEP:** Before doing anything, check https://mynixos.com/home-manager/options/programs.<name> to see if a Home Manager module exists. If it does, ALWAYS use `programs.<name>` — do NOT add to `home.packages`.

```
1. Check MyNixOS for programs.<name> module
   ├── Module EXISTS → Use programs.<name> (create modules/home/<name>.nix)
   │                   NEVER fall back to home.packages for these.
   └── Module does NOT exist
       ├── Needs configuration? → Create modules/home/<name>.nix with home.file.*, etc.
       └── No config needed → Add to home.packages in modules/home/packages.nix
                ├── All platforms → base list
                ├── Linux only    → linuxOnly list
                └── macOS only    → darwinOnly list
                        └── Not in nixpkgs? → Homebrew cask (see below)
```

---

## 1. Bare package — `modules/home/packages.nix`

Add the attribute to the correct list:

```nix
base = with pkgs; [
  # ...existing entries...
  newpackage
];

linuxOnly = with pkgs; [
  # ...existing entries...
  linux-only-pkg
];

darwinOnly = with pkgs; [
  # ...existing entries...
  macos-only-pkg
];
```

Keep entries grouped by purpose (CLI tools, GUI apps, dev tools, etc.) and match the surrounding style.

---

## 2. Home Manager program — `programs.*`

If HM has a module, prefer it over a raw package. Either extend the existing `programs` block in `packages.nix`, or create `modules/home/<name>.nix`:

```nix
# modules/home/<name>.nix
{ pkgs, lib, config, ... }:
{
  programs.<name> = {
    enable = true;
    # ...options...
  };
}
```

`default.nix` auto-imports all sibling `.nix` files, so no manual import is needed — but **run `git add` on the new file** before building or Nix will silently ignore it.

---

## 3. Homebrew cask — `modules/darwin/homebrew.nix` (macOS only)

For GUI apps that are unavailable or broken in nixpkgs on Darwin, add a cask name to the inline list:

```nix
casks = map
  (name: { inherit name; greedy = true; })
  ([
    # ...existing casks...
    "new-app-name"   # ← add here
  ] ++ secrets.homebrewCasks);
```

Cask names must match exactly what `brew search --casks <name>` returns. Use https://formulae.brew.sh/cask/ to look them up.

---

## 4. Cross-platform / machine-specific guards

| Use case | Pattern |
|---|---|
| Linux-only block in HM | `lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { ... }` |
| macOS-only block in HM | `lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { ... }` |
| Main machine only | `lib.mkIf config.me.isMainMachine { ... }` |
| Inline optional packages | `++ optionals (pkgs.stdenv.hostPlatform.isLinux) [ pkg ]` |

---

## 5. After editing

```sh
git add <new-file-if-any>   # untracked files are invisible to Nix
just lint                   # format nix files (nixpkgs-fmt)
just check                  # validate the flake
just run                    # activate the configuration
```
