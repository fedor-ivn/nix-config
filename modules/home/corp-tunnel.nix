# Mac-side half of the two-hop corp SOCKS bridge.
#   Corp half: scripts/corp-tunnel.sh (runs on the corp laptop, outside nix).
#   Design:    openspec/changes/add-corp-split-tunnel/.
#
# Dials back through the reverse-forwarded corp sshd (127.0.0.1:2222) and exposes
# a SOCKS5 proxy on 127.0.0.1:1080 whose traffic egresses from the corp network
# (the SSH *server* for this session is the corp laptop — see Decision 2).
#
# Plain ssh, no autossh: launchd KeepAlive restarts it whenever it exits, and
# ServerAlive makes ssh exit on a dead link — so launchd is the supervisor. No
# backoff needed (launchd throttles respawns to ~10 s), and it only ever touches
# loopback, so the retry loop carries no beacon concern.
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
in
{
  config = lib.mkIf config.me.isMainMachine {
    launchd.agents.corp-tunnel = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.openssh}/bin/ssh"
          "-N"
          "-D"
          "127.0.0.1:1080"
          "-p"
          "2222"
          "-o"
          "ConnectTimeout=3"
          "-o"
          "ServerAliveInterval=30"
          "-o"
          "ServerAliveCountMax=3"
          "-o"
          "ExitOnForwardFailure=yes"
          "-o"
          "StrictHostKeyChecking=accept-new"
          "${corpUser}@localhost"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/corp-tunnel.out.log";
        StandardErrorPath = "/tmp/corp-tunnel.err.log";
      };
    };
  };
}
