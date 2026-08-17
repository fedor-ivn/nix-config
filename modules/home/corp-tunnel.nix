# Mac-side half of the two-hop corp SOCKS bridge.
#   Corp half: scripts/corp-tunnel.sh (runs on the corp laptop, outside nix).
#   Design:    openspec/changes/add-corp-split-tunnel/.
#
# Dials back through the reverse-forwarded corp sshd (127.0.0.1:2222) and exposes
# a SOCKS5 proxy on 127.0.0.1:1080 whose traffic egresses from the corp network
# (the SSH *server* for this session is the corp laptop — see Decision 2).
#
# Plain ssh, no autossh: ServerAlive makes ssh exit on a dead link and launchd
# respawns it, so launchd is the supervisor. It only ever touches loopback, so
# the retry carries no beacon concern.
#
# Event-driven, not polled: the agent probes 127.0.0.1:2222 once and exits 0 if
# the corp laptop is away, and the corp side `launchctl kickstart`s it when its
# reverse-forward lands. See `dialWhenReady` and `KeepAlive` below — launchd has
# no primitive that watches a TCP port (`NetworkState` is unimplemented,
# `PathState` is filesystem-only, and socket activation can't be used because
# `ssh -D` binds :1080 itself), so being told beats looking.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  # The corp laptop's local account (the user that runs corp-tunnel.sh there).
  # Kept out of the public repo via the private `secrets` flake input.
  corpUser = flake.inputs.secrets.values.corpTunnelUser;

  # Dial only when the corp laptop is actually dialed in — checked once, not in
  # a loop. The exit code is the whole mechanism (see KeepAlive below):
  #
  #   corp away  → exit 0    → launchd does NOT respawn (SuccessfulExit = false)
  #   ssh died   → exit != 0 → launchd DOES respawn, so a dropped link redials
  #                            immediately while the corp side is still present
  #
  # That inverts the old behaviour. Previously `KeepAlive = true` respawned ssh
  # against a closed 127.0.0.1:2222 every ~10 s (launchd's throttle) for as long
  # as the corp laptop was away: 692 of 770 lines in one day's log were `connect
  # to host localhost port 2222: Connection refused` — 9 of every 10 log lines
  # were this spin. Now an absent corp laptop costs exactly one 4 ms probe and
  # the job goes quiet until something starts it.
  #
  # What starts it is the corp side: scripts/corp-tunnel.sh `launchctl kickstart`s
  # this agent right after its reverse-forward lands, so arrival is a callback
  # rather than something we poll for. Verified that a kickstart into
  # `gui/<uid>/` succeeds from a stripped environment, which is what an incoming
  # ssh session gets.
  #
  # The probe is a bash net redirection in a subshell (the fd closes with it), so
  # it needs no nc/curl; it only ever touches loopback, so it carries no beacon
  # concern.
  dialWhenReady = pkgs.writeShellScript "corp-tunnel-dial" ''
    if ! (exec 3<>/dev/tcp/127.0.0.1/2222) 2>/dev/null; then
      echo "corp-tunnel: 127.0.0.1:2222 closed, corp laptop not dialed in; idling" >&2
      exit 0
    fi
    echo "corp-tunnel: 127.0.0.1:2222 is open, dialing back" >&2
    exec ${pkgs.openssh}/bin/ssh \
      -N \
      -D 127.0.0.1:1080 \
      -p 2222 \
      -o ConnectTimeout=3 \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -o ExitOnForwardFailure=yes \
      -o StrictHostKeyChecking=accept-new \
      ${corpUser}@localhost
  '';
in
{
  config = lib.mkIf config.me.isMainMachine {
    launchd.agents.corp-tunnel = {
      enable = true;
      config = {
        ProgramArguments = [ "${dialWhenReady}" ];
        # Respawn only on a *failed* exit: ssh dying with the corp side still up
        # redials at once, while the clean "corp is away" exit 0 stops the loop
        # dead. `SuccessfulExit` implies RunAtLoad, so login/activation still
        # probes once.
        KeepAlive.SuccessfulExit = false;
        StandardOutPath = "/tmp/corp-tunnel.out.log";
        StandardErrorPath = "/tmp/corp-tunnel.err.log";
      };
    };
  };
}
