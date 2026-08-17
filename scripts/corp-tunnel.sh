#!/usr/bin/env bash
# Corp-side half of the two-hop bridge — run ON THE CORP LAPTOP, on demand.
# Reverse-forwards the corp laptop's own sshd to the Mac as 127.0.0.1:2222, so
# the Mac can dial back (modules/home/corp-tunnel.nix) and have the SOCKS proxy
# egress from THIS machine. ssh -D cannot be used here — it egresses from the
# server (the Mac). Ctrl-C to stop.
#
# Auto-reconnects so a brief sleep / Wi-Fi blip on the personal Mac heals
# itself. Stock ssh only (no autossh on the locked-down corp laptop): a bash
# loop with capped exponential backoff. After a real session drops it reconnects
# promptly; during a genuine long absence it backs off (+ jitter) so it is not a
# tight fixed-interval beacon. Runs only while you leave it running.
#
# Also kickstarts the Mac's consumer agent once the forward is up (see `KICK`),
# so the proxy is usable seconds after you start this instead of whenever the
# Mac next notices.
set -uo pipefail

MAC="fedorivn@fedorivns-mbp.local"
MIN_BACKOFF=5
MAX_BACKOFF=300
# The Mac-side consumer agent, kickstarted once the forward is up (see below).
MAC_AGENT="gui/501/org.nix-community.home.corp-tunnel"

trap 'echo "corp-tunnel: stopping"; exit 0' INT TERM

# Tell the Mac its dial-back target just appeared.
#
# The Mac agent does not poll for 127.0.0.1:2222 — it probes once and idles — so
# something has to wake it, and the machine that knows the forward is ready is
# this one.
#
# The kick runs as this ssh session's own remote command, not as a separate ssh.
# ssh negotiates remote forwards during session setup and, with
# ExitOnForwardFailure, only opens the session channel once the forward is
# confirmed bound, so the command is guaranteed to run *after* :2222 is
# listening — over the already-authenticated connection, with no second auth and
# no timing assumption about how long the connection took to establish.
#
# `-k` kills any ssh the agent already has: a session whose corp end went stale
# keeps :1080 listening and accepting, so sing-box would route into a black hole
# until ServerAlive times it out ~90 s later. Replacing it outright skips that
# wait.
#
# `sleep 2147483647` then holds the session open for as long as the link lives
# (the loop below handles reconnects). The kickstart's exit status is discarded
# (`;`, not `&&`) so a hiccup there cannot tear down the forward.
KICK="/bin/launchctl kickstart -k $MAC_AGENT >/dev/null 2>&1; exec sleep 2147483647"

backoff=$MIN_BACKOFF
while true; do
  start=$(date +%s)
  ssh \
    -R 2222:localhost:22 \
    -o ConnectTimeout=3 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    "$MAC" "$KICK" || true
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
