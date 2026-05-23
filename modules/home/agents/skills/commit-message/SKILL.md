---
name: commit-message
description: Generate a git commit message based on staged changes and repo style.
user-invocable: true
---

# commit-message

Generate a commit message from the staged diff, following the repo's commit style.

## Style resolution

Resolve which style to use in this order:

1. **Explicit config** — `git config commit.aiMessageStyle` → `conventional` or `simple`
2. **Auto-detect** — `git log --oneline -10`; if ≥50% match `^(type)(\(.+\))?!?: ` → conventional, else → simple
3. **Empty repo** — no commits yet → ask the user which style they want

To set the preference:

```sh
git config commit.aiMessageStyle conventional   # local to this repo
```

## Conventional Commits

Follow the [Conventional Commits 1.0.0 spec](https://www.conventionalcommits.org/en/v1.0.0/).

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only changes |
| `style` | Formatting, whitespace, semicolons (no code logic change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Code change that improves performance |
| `test` | Adding or correcting tests |
| `build` | Changes to build system or external dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Maintenance tasks, tooling, deps that don't fit elsewhere |
| `revert` | Reverting a previous commit |

### Rules

- **Scope** (optional) — a noun in parens describing the affected area: `feat(nix): ...`
- **Breaking changes** — append `!` before the colon: `feat!: ...` or `refactor(api)!: ...`
- **Description** — imperative mood, lowercase first letter, no period at end
- **Body** — free-form, must start with a blank line after description
- **Footers** — `BREAKING CHANGE: <description>`, `Refs: #123`, etc., one blank line after body
- **Line length** — subject ≤72 chars, body lines ≤100 chars

### Examples

```
fix(nix): resolve build failure in me.nix
refactor!: restructure modules/home directory layout
chore(deps): update flake.lock
docs: add AGENTS.md for AI coding assistants
```

---

## Simple style

A clean, imperative style without type prefixes.

### Format

```
<Verb> <object> [<context>]
```

Subject line only — no body, no footer.

### Rules

- **Imperative present-tense verb** as the first word (see vocabulary below)
- **Sentence case** — capitalize the first letter, lowercase the rest unless a proper noun or quoted identifier
- **No trailing period**
- **72-character limit** on the subject line
- **Backtick-quote identifiers** — package names, file names, config keys, CLI tool names, option paths (e.g. `programs.git`)
- **Plain text for conceptual phrases** — `in NixOS configuration`, `for AI assistants`, `on startup`

### Verb vocabulary

| Verb | When to use | Example |
|---|---|---|
| `Add` | Introducing something new | `Add \`lima\` and initialize vps configuration` |
| `Fix` | Correcting a bug or mistake | `Fix typo in user-invocable field` |
| `Update` | Changing an existing value | `Update \`flake.lock\`` |
| `Refactor` | Restructuring without behavior change | `Refactor Linux-specific program configuration` |
| `Configure` | Setting up configuration | `Configure Lima VPS SSH wiring` |
| `Remove` | Deleting something | `Remove unnecessary packages from home configuration` |
| `Rename` | Changing a name | `Rename myUsers option to managedUsers` |
| `Switch` | Replacing one thing with another | `Switch from Google Chrome to ungoogled-chromium` |
| `Enable` | Turning on a feature/option | `Enable zsh as default shell` |
| `Disable` | Turning off a feature/option | `Disable telemetry in Firefox` |
| `Extract` | Moving code/config out into its own file | `Extract SSH config into separate module` |
| `Move` | Relocating files or code | `Move skills into modules/home/agents/` |
| `Revert` | Undoing a previous change | `Revert "Enable telemetry in Firefox"` |
| `Initialize` | First-time setup | `Initialize vps configuration` |
| `Return` | Bringing something back | `Return \`spicetify\`` |
| `Install` | Adding a package | `Install \`posting\`` |
| `Setup` | Setting up infrastructure | `Setup SOPS` |
| `Sync` | Bringing settings from another source | `Sync home manager settings from old nix-darwin config` |
| `Merge` | Merging branches or configs | `Full merge nix-darwin config` |

### Examples

```
Add \`notion plugin\` for claude code
Fix build issues in me.nix and format
Update SSH forwarded port to 53555 in NixOS configuration
Refactor claude code config and define skills alongside the config
Switch from Google Chrome to ungoogled-chromium
```

## Workflow

1. Run `git diff --staged` to inspect the staged changes
2. Resolve the style (see Style resolution above)
3. Generate the commit message following the chosen style's rules
4. Propose the commit command to the user:

   ```sh
   git commit -m "<commit message>"
   ```

5. If the user approves, execute the command
6. If the command fails with:

   ```
   error: Couldn't find key in agent?
   fatal: failed to write commit object
   ```

   tell the user to resolve the issue themselves (e.g., check git signing configuration, GPG/SSH key setup). Do not attempt to fix it automatically.

Only consider staged changes. If nothing is staged, tell the user to stage files first.
