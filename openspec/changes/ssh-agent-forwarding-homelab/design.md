## Context

Deploying to `fedorivns-homelab` requires Nix to fetch the private `nix-secrets` flake input over SSH (`git+ssh://git@github.com/fedor-ivn/nix-secrets`). The homelab has no GitHub SSH key, so the fetch fails. All deployments originate from the MBP (`fedorivns-mbp`), which already has the GitHub SSH key loaded in its agent.

## Goals / Non-Goals

**Goals:**
- `just a homelab` from the MBP successfully builds and deploys `fedorivns-homelab`, including fetching the private `nix-secrets` input
- No SSH key material is stored on the homelab disk

**Non-Goals:**
- Self-updating homelab (homelab running its own deploy without MBP)
- Supporting deploy from any host other than the MBP

## Decisions

### Decision 1: SSH agent forwarding over key-on-disk

Forward the MBP's `ssh-agent` socket to the homelab rather than placing a GitHub SSH key on the homelab.

**Why**: The homelab's disk is LUKS-encrypted, so a key at rest is protected — but it still requires managing a second private key, rotating it, and keeping it in KeePassXC. Agent forwarding requires zero key material on the homelab and piggybacks on the existing SSH connection that the deploy already opens.

**Alternative considered**: Export GitHub SSH key from KeePassXC to `~/.ssh/` on the homelab at bootstrap (same pattern as the age key). Rejected because the agent forwarding approach has no persistent secret on the server side.

### Decision 2: Preserve `SSH_AUTH_SOCK` across sudo via sudoers

`nixos-rebuild switch` (invoked by `nixos-unified`/`just a`) runs under sudo. By default, sudo strips environment variables including `SSH_AUTH_SOCK`, breaking the forwarded agent.

Add `Defaults env_keep+=SSH_AUTH_SOCK` to the homelab's sudoers via `security.sudo.extraConfig`.

**Why**: This is the standard, minimal fix. The alternative (running nixos-rebuild as the user, not root) would require restructuring the activation flow.

### Decision 3: Add `homelab` alias to Justfile

Extend the `activate` recipe to recognize `homelab` as a valid host alias, mapping to `fedorivns-homelab`.

**Why**: Keeps the UX consistent with `just a thinkpad`. The MBP SSH config (with `ForwardAgent yes`) and the homelab sudoers config together are inert until a deploy actually runs, so the Justfile alias is the user-facing entry point.

### Decision 4: MBP SSH config via home-manager

Add the `Host fedorivns-homelab.local` stanza with `ForwardAgent yes` to the MBP's SSH config, managed declaratively through home-manager (`programs.ssh.settings."fedorivns-homelab.local".ForwardAgent`).

**Why**: Keeps all MBP config in the flake. Manual `~/.ssh/config` edits would be overwritten on the next home-manager activation.

## Risks / Trade-offs

- **Agent forwarding is a privilege escalation vector** → Mitigation: the homelab is a trusted, single-user machine on a private network. Agent forwarding to untrusted hosts would be a problem; this host is not untrusted.
- **Deploy fails if MBP agent has no GitHub key loaded** → Mitigation: this is the same requirement as any other operation that needs the GitHub SSH key (e.g., `git push`). No new failure mode introduced.
- **`SSH_AUTH_SOCK` env_keep broadens the sudo attack surface slightly** → Mitigation: only the `fedorivn` user can SSH into the homelab (PasswordAuthentication off, authorized keys set). Acceptable.
