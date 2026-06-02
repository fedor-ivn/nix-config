## ADDED Requirements

### Requirement: Ghostty shell integration propagates terminfo over SSH
The home-manager Ghostty module SHALL have `shell-integration-features` set to include `ssh-env` and `ssh-terminfo`, enabling automatic terminfo installation on remote hosts at connect time.

#### Scenario: SSH into arbitrary non-NixOS remote
- **WHEN** user opens an SSH session from Ghostty to a host without xterm-ghostty terminfo
- **THEN** Ghostty shell integration copies terminfo to the remote via `tic` and the session starts without terminfo errors

#### Scenario: Repeated SSH to same host
- **WHEN** user connects a second time to the same remote
- **THEN** the session starts immediately (terminfo already installed, no repeated copy overhead)

### Requirement: All NixOS hosts in the flake have ghostty terminfo pre-installed
The shared NixOS module (`modules/nixos/common/default.nix`) SHALL include `pkgs.ghostty.terminfo` in `environment.systemPackages`, so every managed NixOS host is a valid SSH target for Ghostty users.

#### Scenario: SSH from Ghostty into fedorivns-thinkpad
- **WHEN** user SSHes from Ghostty into any NixOS host managed by this flake
- **THEN** no terminfo error occurs (terminfo pre-installed via system packages)

#### Scenario: New NixOS host added to flake
- **WHEN** a new NixOS host configuration is added that imports the common module
- **THEN** it inherits ghostty terminfo automatically with no additional configuration

### Requirement: Shell provides ghostty +ssh alias as fallback wrapper
The shared home-manager shell config (`modules/home/shell.nix`) SHALL define `ssh = "ghostty +ssh"` in `home.shellAliases`, providing a drop-in SSH wrapper that handles terminfo for hosts where shell integration cannot auto-copy (e.g., restricted environments).

#### Scenario: SSH to host where tic is unavailable
- **WHEN** user runs `ssh` on a host where shell integration terminfo copy fails
- **THEN** `ghostty +ssh` wrapper handles the session with appropriate TERM fallback

#### Scenario: SSH flags and arguments passed through
- **WHEN** user runs `ssh -p 2222 user@host` or any standard ssh invocation
- **THEN** all arguments are forwarded verbatim to the real `ssh` binary
