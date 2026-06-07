# Spec: Homelab Deploy

## Purpose

Deploying NixOS configurations to `fedorivns-homelab` from `fedorivns-mbp` via SSH agent forwarding, enabling the remote build to authenticate to GitHub for private flake inputs (e.g. `nix-secrets`) without embedding credentials on the homelab host.

## Requirements

### Requirement: Deploy to homelab from MBP
Running `just a homelab` from `fedorivns-mbp` SHALL successfully build and activate `fedorivns-homelab`'s NixOS configuration, including fetching the private `nix-secrets` flake input via the MBP's forwarded SSH agent.

#### Scenario: Successful deploy with agent forwarding
- **WHEN** the user runs `just a homelab` on `fedorivns-mbp` with a GitHub SSH key loaded in the local agent
- **THEN** the deploy connects to `fedorivns-homelab.local`, fetches all flake inputs (including `nix-secrets`), builds the system closure, and activates it without prompting for credentials

#### Scenario: Deploy fails without GitHub key in agent
- **WHEN** the user runs `just a homelab` but no GitHub SSH key is loaded in the MBP's agent
- **THEN** the deploy fails during `nix-secrets` flake fetch with an SSH authentication error (not a silent failure)

### Requirement: Agent socket available under sudo on homelab
On `fedorivns-homelab`, `SSH_AUTH_SOCK` SHALL be preserved when the deploy process escalates to sudo, so that `nixos-rebuild switch` can use the forwarded agent to authenticate to GitHub.

#### Scenario: SSH_AUTH_SOCK preserved through sudo
- **WHEN** the deploy SSH session has a forwarded agent socket and runs a command under sudo
- **THEN** `sudo env | grep SSH_AUTH_SOCK` returns the forwarded socket path

### Requirement: MBP SSH config declares agent forwarding for homelab
The MBP's home-manager SSH configuration SHALL include `ForwardAgent yes` for `fedorivns-homelab.local` so agent forwarding is automatic and not dependent on manual flags. Configured via `programs.ssh.settings."fedorivns-homelab.local".ForwardAgent = true`.

#### Scenario: ForwardAgent in generated SSH config
- **WHEN** home-manager is activated on `fedorivns-mbp`
- **THEN** `~/.ssh/config` contains a `Host fedorivns-homelab.local` block with `ForwardAgent yes`
