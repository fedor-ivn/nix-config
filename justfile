# Like GNU `make`, but `just` rustier.
# https://just.systems/
# run `just` from this directory to see available commands

# Default command when 'just' is run without arguments
default:
  @just --list

# Update nix flake
[group('Main')]
update:
  nix flake update

# Commit flake.lock after update
[group('Main')]
commit-flake-lock:
  git add flake.lock
  git commit -m 'Update `flake.lock`'

# Clean up old nix store paths and GC roots
[group('Main')]
clean:
  sudo nix-collect-garbage -d

# Update nix flake and commit flake.lock
[group('Main')]
update-and-commit:
  just update
  just commit-flake-lock

# Refresh the sing-box subscription nodes in secrets.yaml.
# The URL is read from secrets.yaml itself (`sing-box/subscription-url`).
#
# Stores the nodes PLUS the `proxy-auto` urltest and `proxy` selector over them,
# WITHOUT enclosing brackets — modules/home/sing-box.nix splices the lot into a
# JSON array. The groups live in here rather than in nix so that no node tag
# reaches the world-readable Nix store. Re-run after the provider changes nodes,
# then `just a` and re-import the profile into SFM.
[group('Main')]
refresh-sing-box-subscription:
  #!/usr/bin/env bash
  set -euo pipefail
  url="$(sops decrypt --extract '["sing-box"]["subscription-url"]' secrets.yaml)"
  nodes="$(curl -fsS --max-time 30 -A 'SFM/1.14.0' "$url/singbox" \
    | jq -c '[ .outbounds[]
               | select(.type | IN("direct","block","dns","selector","urltest") | not)
               | .tag = "ameno/" + .tag ]')"
  [ "$(jq 'length' <<<"$nodes")" -gt 0 ] || { echo "no nodes returned; aborting" >&2; exit 1; }
  echo "nodes fetched:"
  jq -r '.[].tag | "  " + .' <<<"$nodes"
  # `wg` and `direct` come from lib/sing-box/default.nix; tags resolve globally.
  group="$(jq -c '. + [
    { type: "urltest", tag: "proxy-auto", outbounds: [ .[].tag ],
      url: "https://www.gstatic.com/generate_204", interval: "3m" },
    { type: "selector", tag: "proxy",
      outbounds: ([ "proxy-auto", "wg", "direct" ] + [ .[].tag ]),
      default: "proxy-auto" }
  ]' <<<"$nodes")"
  sops set secrets.yaml '["sing-box"]["proxy-outbounds"]' \
    "$(jq -Rc . <<<"$(jq -c '.[]' <<<"$group" | paste -sd, -)")"

# Lint nix files
[group('dev')]
fmt:
  nix fmt .

# Check nix flake
[group('dev')]
check:
  nix flake check

alias a := activate

# Activate the configuration. Pass a host to activate remotely: just activate thinkpad
[group('Main')]
activate host="":
  nix run .#activate {{ 
    if host == "" {
       ""
    } else if host == "thinkpad" {
      "fedorivns-thinkpad"
    } else if host == "homelab" {
      "fedorivns-homelab"
    } else {
      error("Unknown host '" + host + "'. Available: thinkpad, homelab")
    }
  }}
