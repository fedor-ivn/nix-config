# sing-box split-tunnel configs for a personal machine, generated from one source.
#
# The profiles live in lib/sing-box/profiles. This module supplies only the
# host-specific parts — the platform and where the subscription nodes come from.
#
# Enabled per host (see configurations/darwin/<host>/). The homelab does not use
# this module: it runs sing-box as a system service instead (see
# modules/nixos/sing-box.nix).
#
# Both profiles are rendered by sops-nix at *activation* time, so no node
# credential enters the world-readable Nix store: the nodes live in secrets.yaml
# under `sing-box/proxy-outbounds` and are interpolated through a placeholder.
# Refresh them with `just refresh-sing-box-subscription` — sing-box has no
# subscription support of its own. Reasoning in
# openspec/specs/split-tunnel-router/design-notes.md.
#
# The rendered files are symlinked into ~/.sing-box/{personal,corp}.json (out of
# store) and, where `programs.singBox.server.enable` is set, served over loopback
# for SFM to fetch as two *Remote* profiles:
#
#   http://127.0.0.1:18088/personal.json
#   http://127.0.0.1:18088/corp.json
#
# Pick `corp.json` when the reverse-SSH SOCKS bridge (127.0.0.1:1080) is up,
# `personal.json` otherwise.
#
# ## Why a server
#
# SFM *copies* a local profile's contents into its own store at import time, so
# every `just a` used to leave the file on disk while the config SFM actually ran
# silently diverged until you re-imported by hand. A loopback URL makes SFM
# re-read the rendered file, so an activation propagates on the next poll with no
# manual step.
#
# This is not the "Remote Profile = subscription URL" idea the design notes
# reject: that hands SFM the *provider's* config and throws away the routing.
# Here SFM fetches the profile generated above; only the delivery path changes.
#
# Serving the symlink chain is the whole trick, and it constrains the server:
#
#   ~/.sing-box/personal.json
#     -> /nix/store/...-hm_singboxpersonal.json          (mkOutOfStoreSymlink)
#     -> ~/.config/sops-nix/secrets/rendered/...         (per-generation symlink)
#     -> $TMPDIR/secrets.d/<generation>/rendered/...     (the real file)
#
# `<generation>` increments on every activation, so the server must re-resolve the
# chain per request rather than cache a path. Two things follow: **never pass
# `--chroot`** (it would cut off the escape into $TMPDIR), and do not swap in a
# caching server without re-testing that property.
#
# Cost: the rendered files are mode 0400, but a listener widens read access to
# anything that can reach loopback — other local accounts, sandboxed apps with
# network but no filesystem access. Anything running as this user loses nothing.
# Accepted on a single-user laptop.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.singBox;

  singBox = import ../../lib/sing-box;
  inherit (singBox) render;

  profileDir = "${config.home.homeDirectory}/.sing-box";

  # Template text plus its build-time `sing-box check`, for one profile.
  mkProfile = name: profile: render.mkProfile {
    inherit pkgs name profile;
    placeholders = config.sops.placeholder;
    args = {
      inherit lib;
      # SFM runs sing-box as a NetworkExtension, where `route_exclude_address`
      # is a route fight with Tailscale — see the tun comment in
      # lib/sing-box/parts/core.nix.
      platform = "darwin";
    };
  };

  # Every profile this host renders, keyed by the name the rest of the module
  # derives everything else from: the sops template, the symlink SFM reads and
  # the build-time check. Listed rather than taken wholesale from
  # `singBox.profiles`, so adding a profile to the library does not silently
  # start rendering it here.
  profiles = lib.mapAttrs mkProfile {
    inherit (singBox.profiles) personal corp;
  };
in
{
  options.programs.singBox.enable = lib.mkEnableOption ''
    user-level sing-box configs for SFM (the GUI app), rendered to
    ~/.sing-box/{personal,corp}.json and served over loopback for SFM to fetch
    as Remote profiles. Requires `sing-box/proxy-outbounds` in secrets.yaml —
    refresh it with `just refresh-sing-box-subscription`
  '';

  options.programs.singBox.server = {
    # Off by default and switched on by the platform that can actually run it:
    # modules/darwin/default.nix sets this for every Darwin host, because the
    # server is a `launchd.agents` entry and SFM — the only thing that fetches
    # these profiles — is a mac app.
    enable = lib.mkEnableOption ''
      serving the rendered profiles over loopback so SFM can consume them as
      Remote profiles instead of needing a manual re-import after every
      activation. Has no effect unless `programs.singBox.enable` is also set
    '';

    port = lib.mkOption {
      type = lib.types.port;
      default = 18088;
      description = ''
        Loopback port SFM fetches the rendered profiles from. Avoid 1080 (the
        corp reverse-SSH SOCKS bridge) and 9090 (sing-box's Clash API).
        Changing it means re-pointing the Remote profile URLs in SFM by hand.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      sops.secrets.${render.proxySecret} = { };

      sops.templates = lib.mapAttrs'
        (name: profile: lib.nameValuePair "sing-box-${name}.json" {
          content = profile.content;
        })
        profiles;

      home.file = lib.mapAttrs'
        (name: _: lib.nameValuePair ".sing-box/${name}.json" {
          source = config.lib.file.mkOutOfStoreSymlink
            config.sops.templates."sing-box-${name}.json".path;
        })
        profiles;

      # Force the checks into the activation closure so a broken profile fails the
      # build rather than SFM.
      home.extraActivationPath = lib.mapAttrsToList (_: profile: profile.check) profiles;
    }

    # Serves exactly the two profile symlinks above, so anything else dropped in
    # that directory would be served too — keep it to profiles.
    #
    # `--addr 127.0.0.1` is load-bearing: darkhttpd binds every interface by
    # default, which would put the node credentials on the LAN. No `--chroot`
    # (see the header). `--default-mimetype` rather than a mimetype file, since
    # the directory only ever holds JSON.
    #
    # sops-nix has its own RunAtLoad agent that re-renders into a fresh generation
    # directory, and nothing orders this agent against it, so at login — and on
    # every activation, where `setupLaunchAgents` runs before `sops-nix` — there
    # is a window where this server is up against the previous generation.
    # Harmless only because darkhttpd re-resolves per request; KeepAlive would not
    # help, since the server is up and it is the files that are stale. SFM keeps
    # its last good profile across a failed update.
    (lib.mkIf cfg.server.enable {
      launchd.agents.sing-box-profiles = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.darkhttpd}/bin/darkhttpd"
            profileDir
            "--addr"
            "127.0.0.1"
            "--port"
            (toString cfg.server.port)
            "--no-listing"
            "--default-mimetype"
            "application/json"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/tmp/sing-box-profiles.out.log";
          StandardErrorPath = "/tmp/sing-box-profiles.err.log";
        };
      };
    })
  ]);
}
