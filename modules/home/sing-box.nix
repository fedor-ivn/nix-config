# sing-box split-tunnel configs for a personal machine, generated from one source.
#
# The generators live in lib/sing-box: the base (personal) profile and the corp
# overlay, which adds the FakeIP DNS server, the SOCKS outbound and the corp
# route rule. This module only supplies the host-specific parts — where to read
# the subscription nodes from.
#
# Enabled per host (see configurations/darwin/<host>/). The homelab does not use
# this module: it runs sing-box as a system service instead (see
# modules/nixos/sing-box.nix).
#
# Both profiles are rendered by sops-nix at *activation* time, so no node
# credential enters the world-readable Nix store: the nodes live in secrets.yaml
# under `sing-box/proxy-outbounds` and are interpolated via a placeholder.
#
# The rendered files are symlinked into ~/.sing-box/{personal,corp}.json (out of
# store) and, where `programs.singBox.server.enable` is set, served over loopback
# (see "Why a server" below) and added to SFM as two *Remote* profiles:
#
#   http://127.0.0.1:18088/personal.json
#   http://127.0.0.1:18088/corp.json
#
# Pick `corp.json` when the reverse-SSH SOCKS bridge (127.0.0.1:1080) is up,
# `personal.json` otherwise.
#
# Default traffic leaves through subscription nodes. They are baked in here
# rather than fetched at runtime because sing-box has no subscription support.
# That is only workable because the subscription's output is byte-stable;
# refresh it with `just refresh-sing-box-subscription`. Full reasoning in
# openspec/specs/split-tunnel-router/design-notes.md.
#
# Validated at build time against nixpkgs' sing-box via `lib/sing-box/render.nix`
# `checkable`, which renders the same document with dummy secrets. That used to
# be impossible for two reasons, both now gone: SFM tracked 1.14.x while nixpkgs
# lagged on 1.13.x (both are 1.14 now), and the template is not valid JSON until
# sops substitutes it (hence the dummy-node render).
#
# The server is enabled by modules/darwin/default.nix for every mac, not by a
# platform check in here — see `programs.singBox.server.enable`.
#
# ## Why a server
#
# SFM *copies* a local profile's contents into its own store at import time. So
# every `just a` used to leave the file on disk and the config SFM actually runs
# silently diverged until you remembered to re-import by hand. Pointing SFM at a
# loopback URL instead makes it re-read the rendered file, so an activation
# propagates on the next poll (or the Update button) with no manual step.
#
# This is not the "Remote Profile = subscription URL" idea the design notes
# reject. That one throws away the corp/RU routing, because it hands SFM the
# *provider's* config. Here SFM fetches the profile this module generates; the
# routing is untouched and only the delivery path changes.
#
# Serving the symlink chain is the whole trick, and it constrains the server:
#
#   ~/.sing-box/personal.json
#     -> /nix/store/...-hm_singboxpersonal.json          (mkOutOfStoreSymlink)
#     -> ~/.config/sops-nix/secrets/rendered/...         (per-generation symlink)
#     -> $TMPDIR/secrets.d/<generation>/rendered/...     (the real file)
#
# `<generation>` increments on every activation, so the server must re-resolve
# the chain per request rather than hold an fd or cache a path — verified
# against darkhttpd by swapping a generation symlink under a live server and
# watching the served bytes change. Two things follow: **never pass `--chroot`**
# (it would cut off the escape into $TMPDIR), and do not swap in a caching
# server without re-testing that property.
#
# ## What this costs
#
# The rendered files are mode 0400 and stay that way, but a listener widens read
# access to anything that can reach loopback — in practice other local user
# accounts, and sandboxed apps that have network but not filesystem access.
# Anything already running as this user loses nothing, since it can read the
# file directly today. Accepted on a single-user laptop.
#
# Closing that gap would need an unguessable path component, and the token
# cannot come from Nix: both `home.file` paths and `inputs.secrets` values land
# in the world-readable store, which defeats the point. It would take an
# activation script minting the directory once — deliberately not done.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.singBox;

  # Marker, secret name and the splice itself — shared with the NixOS module,
  # which renders the same way.
  render = import ../../lib/sing-box/render.nix;

  # Nothing host-specific is left on the mac: the tun defaults in the generator
  # are the macOS ones. Kept as a name so both profiles and both checks stay in
  # step if that changes again.
  hostArgs = { };

  profileDir = "${config.home.homeDirectory}/.sing-box";

  renderConfig = generator: render.render {
    placeholders = config.sops.placeholder;
    inherit generator;
    args = hostArgs;
  };

  # Schema check against a real binary, on the dummy-secret render. `check` does
  # not catch everything — a detour to an empty direct outbound passes here and
  # is fatal at start — but it catches typos and shape errors before activation.
  configCheck = name: generator: pkgs.runCommand "sing-box-check-${name}"
    {
      nativeBuildInputs = [ pkgs.sing-box ];
      configJson = render.checkable { inherit generator; args = hostArgs; };
      passAsFile = [ "configJson" ];
    } ''
    sing-box check -c "$configJsonPath"
    touch $out
  '';
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
    # these profiles — is a mac app. A Linux host would need a systemd user unit
    # and nothing wants one: the homelab runs sing-box as a system service off
    # its own config (modules/nixos/sing-box.nix) and never fetches a profile.
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

      sops.templates."sing-box-personal.json".content =
        renderConfig ../../lib/sing-box;
      sops.templates."sing-box-corp.json".content =
        renderConfig ../../lib/sing-box/corp.nix;

      home.file.".sing-box/personal.json".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-personal.json".path;
      home.file.".sing-box/corp.json".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-corp.json".path;

      # Force the checks into the activation closure so a broken profile fails the
      # build rather than SFM.
      home.extraActivationPath = [
        (configCheck "personal" ../../lib/sing-box)
        (configCheck "corp" ../../lib/sing-box/corp.nix)
      ];
    }

    # Serves exactly the two profile symlinks above, so anything else dropped in
    # that directory would be served too — keep it to profiles.
    #
    # `--addr 127.0.0.1` is load-bearing: darkhttpd binds every interface by
    # default, which would put the node credentials on the LAN. No `--chroot`
    # (it would cut off the symlink escape into $TMPDIR — see the header).
    # `--default-mimetype` rather than a mimetype file, since the directory only
    # ever holds JSON.
    #
    # sops-nix has its own RunAtLoad agent that re-renders into a fresh
    # generation directory, and nothing orders this agent against it, so at login
    # — and on every activation, where `setupLaunchAgents` runs before `sops-nix`
    # — there is a window where this server is up against the previous
    # generation. Harmless only because darkhttpd re-resolves per request;
    # KeepAlive would not help, since the server is up and it is the files that
    # are stale. SFM keeps its last good profile across a failed update.
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
