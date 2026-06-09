## ADDED Requirements

### Requirement: Choose primitive based on runtime dependencies
A Nix shell script MUST use `writeShellApplication` when it requires runtime packages (i.e., has a non-empty `runtimeInputs`), and MUST use `writeShellScriptBin` when it has no runtime dependencies.

#### Scenario: Script needs external tools
- **WHEN** a script invokes tools like `jq`, `gh`, or `taskwarrior3`
- **THEN** it SHALL be declared with `writeShellApplication` and list those tools in `runtimeInputs`

#### Scenario: Script needs no external tools
- **WHEN** a script only calls builtins or tools already on PATH (e.g., `task` via the user's environment)
- **THEN** it SHALL be declared with `writeShellScriptBin`

### Requirement: Omit shebang inside Nix-managed scripts
A shell script declared with `writeShellScriptBin` or `writeShellApplication` MUST NOT include a `#!/usr/bin/env bash` (or any other) shebang line. Nix wraps the script in a bash invocation automatically; a shebang inside the string literal is inert and misleading.

#### Scenario: Shebang present in script body
- **WHEN** a script body begins with `#!/usr/bin/env bash`
- **THEN** that line SHALL be removed

### Requirement: Omit explicit `set -euo pipefail` inside `writeShellApplication`
A script declared with `writeShellApplication` MUST NOT include `set -euo pipefail` in its `text`. `writeShellApplication` prepends these flags automatically; duplicating them is redundant.

#### Scenario: Explicit set flags in writeShellApplication
- **WHEN** a `writeShellApplication` script body contains `set -euo pipefail`
- **THEN** that line SHALL be removed

### Requirement: Omit trailing `exit 0`
Scripts MUST NOT end with `exit 0`. Bash exits 0 by default when the last command succeeds; an explicit `exit 0` adds noise without effect.

#### Scenario: Script ends with `exit 0`
- **WHEN** the last statement in a script body is `exit 0`
- **THEN** that line SHALL be removed

### Requirement: No redundant `pkgs.` inside `with pkgs;`
Within a `with pkgs;` scope (e.g., `runtimeInputs = with pkgs; [ ... ]`), package names MUST NOT be prefixed with `pkgs.`. The `with` expression already brings all `pkgs` attributes into scope.

#### Scenario: Redundant prefix in runtimeInputs
- **WHEN** `runtimeInputs = with pkgs; [ jq pkgs.taskwarrior3 ]` appears
- **THEN** it SHALL be written as `[ jq taskwarrior3 ]`

### Requirement: Argument-accepting scripts validate their arguments
A script that requires one or more positional arguments MUST validate their presence at the start of the script body and print a usage message before exiting non-zero if they are absent.

#### Scenario: Script called with no argument
- **WHEN** a script that requires `$1` is invoked without arguments
- **THEN** it SHALL print `Usage: <script-name> <arg>` to stdout and exit with code 1

### Requirement: No comments that describe what the code does
Comments in script bodies MUST NOT describe what the immediately following code does (e.g., `# Fetch the task`, `# Determine URL opener`). Well-named variables and commands are self-descriptive. Only non-obvious WHY comments (hidden constraints, workarounds) are permitted.

#### Scenario: Comment restates the code
- **WHEN** removing a comment would not confuse a reader familiar with bash
- **THEN** the comment SHALL be removed
