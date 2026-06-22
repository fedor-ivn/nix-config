#!/usr/bin/env bash
# Corp-side half of the two-hop bridge — run ON THE CORP LAPTOP, on demand.
# Reverse-forwards the corp laptop's own sshd to the Mac as 127.0.0.1:2222, so
# the Mac can dial back (corp-tunnel-mac.sh) and have the SOCKS proxy egress
# from THIS machine. ssh -D cannot be used here — it egresses from the server
# (the Mac). Ctrl-C to stop.
#
# Auto-reconnects so a brief sleep / Wi-Fi blip on the personal Mac heals
# itself. Stock ssh only (no autossh on the locked-down corp laptop): a bash
# loop with capped exponential backoff. After a real session drops it reconnects
# promptly; during a genuine long absence it backs off (+ jitter) so it is not a
# tight fixed-interval beacon. Runs only while you leave it running.
set -uo pipefail

MAC="fedorivn@fedorivns-mbp.local"
MIN_BACKOFF=5
MAX_BACKOFF=300

trap 'echo "corp-tunnel: stopping"; exit 0' INT TERM

backoff=$MIN_BACKOFF
while true; do
  start=$(date +%s)
  ssh -N \
    -R 2222:localhost:22 \
    -o ConnectTimeout=3 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    "$MAC" || true
  elapsed=$(( $(date +%s) - start ))

  if [ "$elapsed" -ge 60 ]; then
    # Was an established session (e.g. dropped by a brief Mac sleep) →
    # reconnect promptly.
    backoff=$MIN_BACKOFF
  else
    # Quick failure (Mac unreachable / off-LAN) → back off, capped.
    backoff=$(( backoff * 2 ))
    [ "$backoff" -gt "$MAX_BACKOFF" ] && backoff=$MAX_BACKOFF
  fi

  # ±~25% jitter so the cadence is not perfectly regular.
  jitter=$(( (RANDOM % (backoff / 2 + 1)) - backoff / 4 ))
  wait_s=$(( backoff + jitter ))
  [ "$wait_s" -lt 1 ] && wait_s=1
  sleep "$wait_s"
done
