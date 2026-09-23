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
  # Nodes the provider serves but that do not carry traffic — see
  # `just exclude-sing-box-nodes`. Optional: an absent key excludes nothing.
  excluded="$(sops decrypt --extract '["sing-box"]["excluded-nodes"]' secrets.yaml 2>/dev/null || true)"
  excluded="${excluded:-[]}"
  fetched="$(curl -fsS --max-time 30 -A 'SFM/1.14.0' "$url/singbox" \
    | jq -c '[ .outbounds[]
               | select(.type | IN("direct","block","dns","selector","urltest") | not)
               | .tag = "ameno/" + .tag ]')"
  echo "nodes fetched:"
  jq -r --argjson excluded "$excluded" \
    '.[].tag | if IN($excluded[]) then "  skip " + . else "  keep " + . end' <<<"$fetched"
  nodes="$(jq -c --argjson excluded "$excluded" \
    'map(select(.tag | IN($excluded[]) | not))' <<<"$fetched")"
  [ "$(jq 'length' <<<"$nodes")" -gt 0 ] || { echo "no nodes left after exclusions; aborting" >&2; exit 1; }
  # `direct` comes from lib/sing-box/default.nix; tags resolve globally.
  group="$(jq -c '. + [
    { type: "urltest", tag: "proxy-auto", outbounds: [ .[].tag ],
      url: "https://www.gstatic.com/generate_204", interval: "3m" },
    { type: "selector", tag: "proxy",
      outbounds: ([ "proxy-auto", "direct" ] + [ .[].tag ]),
      default: "proxy-auto" }
  ]' <<<"$nodes")"
  sops set secrets.yaml '["sing-box"]["proxy-outbounds"]' \
    "$(jq -Rc . <<<"$(jq -c '.[]' <<<"$group" | paste -sd, -)")"

# Drop subscription nodes that the provider serves but that do not work, so
# `refresh-sing-box-subscription` leaves them out of both groups.
#
# `proxy-auto` cannot find these itself: it probes a 204 with an empty body, so
# a node that completes the handshake and then black-holes anything past ~8 KB
# measures as healthy — often as the *fastest* node, which is how one of them
# ends up carrying all traffic. Until the probe can see that, the list is
# maintained by hand from `just check-sing-box-nodes`.
#
# The tags live in secrets.yaml for the same reason the groups do (see above):
# a node tag in the repo leaks the provider and its rough geography. The list
# is replaced, not appended, so no arguments clears it.
#
# Drop named subscription nodes from both proxy groups
[group('Main')]
exclude-sing-box-nodes *TAGS:
  #!/usr/bin/env bash
  set -euo pipefail
  list="$(jq -nc '$ARGS.positional' --args {{ TAGS }})"
  sops set secrets.yaml '["sing-box"]["excluded-nodes"]' "$(jq -Rc . <<<"$list")"
  echo "excluded:"
  jq -r 'if length == 0 then "  (none)" else .[] | "  " + . end' <<<"$list"
  echo "now run: just refresh-sing-box-subscription && just a"

# Each node gets its own loopback inbound in a throwaway sing-box (no tun, so
# nothing touches the running tunnel) and is asked for 1 KB and then 64 KB. A
# node that passes the first and fails the second is the failure `proxy-auto` is
# blind to: it completes the handshake, wins the urltest on latency, and then
# black-holes every page load. Feed those to `just exclude-sing-box-nodes`.
#
# Probe each subscription node, including for large-transfer black holes
[group('dev')]
check-sing-box-nodes config="~/.sing-box/personal.json":
  #!/usr/bin/env bash
  set -euo pipefail
  src="{{ config }}"; src="${src/#\~/$HOME}"
  dir="$(mktemp -d)"; trap 'rm -rf "$dir"' EXIT
  jq '[ .outbounds[] | select(.type | IN("direct","urltest","selector") | not) | .tag ] as $tags
      | .inbounds = [ $tags | to_entries[]
          | { type: "mixed", tag: ("in" + (.key|tostring)),
              listen: "127.0.0.1", listen_port: (16000 + .key) } ]
      | .route.rules = [ $tags | to_entries[]
          | { inbound: [ "in" + (.key|tostring) ], outbound: .value } ]
      | .dns.rules = [] | .dns.final = "direct-dns"
      | .log = { level: "error", timestamp: true }
      | .experimental = {}' "$src" > "$dir/cfg.json"
  jq -r '[ .outbounds[] | select(.type | IN("direct","urltest","selector") | not) | .tag ][]' \
    "$src" > "$dir/tags"
  # SFM ships its own sing-box inside the .app, so there is usually none on PATH.
  if command -v sing-box >/dev/null; then box=(sing-box); else
    box=(nix shell nixpkgs#sing-box -c sing-box); fi
  "${box[@]}" run -c "$dir/cfg.json" >"$dir/log" 2>&1 &
  pid=$!; trap 'kill $pid 2>/dev/null || true; rm -rf "$dir"' EXIT
  for _ in $(seq 100); do nc -z 127.0.0.1 16000 >/dev/null 2>&1 && break; sleep 0.1; done
  i=0
  printf '%-34s %-14s %-14s %s\n' NODE 1KB 64KB VERDICT
  while read -r tag; do
    # curl writes %{size_download} even when it gives up, so a failure still
    # reports how far the transfer got — which is the whole signal here.
    get() { local got
            got="$(curl -fsS -x "socks5h://127.0.0.1:$((16000+i))" -o /dev/null \
                     -w '%{size_download}' --max-time "$2" \
                     "https://speed.cloudflare.com/__down?bytes=$1" 2>/dev/null)" \
              && { echo "$got"; return; }
            echo "stalled@${got:-0}"; }
    small="$(get 1000 10)"; big="$(get 65536 20)"
    if   [ "$small" != 1000 ];  then verdict="DEAD — never connects"
    elif [ "$big" != 65536 ];   then verdict="BLACK HOLE — exclude this one"
    else                             verdict="ok"; fi
    printf '%-34s %-14s %-14s %s\n' "$tag" "$small" "$big" "$verdict"
    i=$((i+1))
  done < "$dir/tags"

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
