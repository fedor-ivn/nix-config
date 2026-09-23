# sing-box split-tunnel configs for a personal machine, generated from one source.
#
# The generators live in lib/sing-box: the base (personal) profile and the corp
# overlay, which adds the FakeIP DNS server, the SOCKS outbound and the corp
# route rule. This module only supplies the host-specific parts — where to read
# the host's WireGuard identity and the subscription nodes from.
#
# Enabled per host (see configurations/darwin/<host>/). The homelab does not use
# this module: it runs sing-box as a system service instead (see
# modules/nixos/sing-box.nix).
#
# Both profiles are rendered by sops-nix at *activation* time, so nothing about
# the WireGuard identity — keys or tunnel addresses — enters the world-readable
# Nix store. It all lives in secrets.yaml under `wireguard/<hostname>/*` and is
# interpolated via placeholders.
#
# The rendered files are symlinked into ~/.sing-box/{personal,corp}.json (out of
# store), which you import into SFM. Pick `corp.json` when the reverse-SSH SOCKS
# bridge (127.0.0.1:1080) is up, `personal.json` otherwise.
#
# Default traffic leaves through subscription nodes rather than WireGuard — the
# `snejugal.ru` exit is banned. The nodes are baked in here rather than fetched
# at runtime because sing-box has no subscription support and SFM's "remote
# profile" replaces the *whole* config, which would discard the corp/RU routing
# this module exists for. That is only workable because the subscription's
# output is byte-stable; refresh it with
# `just refresh-sing-box-subscription`. Full reasoning in
# openspec/specs/split-tunnel-router/design-notes.md.
#
# Validated at build time against nixpkgs' sing-box via `lib/sing-box/render.nix`
# `checkable`, which renders the same document with dummy secrets. That used to
# be impossible for two reasons, both now gone: SFM tracked 1.14.x while nixpkgs
# lagged on 1.13.x (both are 1.14 now), and the template is not valid JSON until
# sops substitutes it (hence the dummy-node render).
{ config, lib, pkgs, osConfig ? { }, ... }:
let
  cfg = config.programs.singBox;

  # The WireGuard identity is per-host, so the secrets to read follow the machine
  # this account is activating on rather than being hardcoded to one hostname.
  secret = name: "wireguard/${osConfig.networking.hostName}/${name}";

  # `endpoints[0].address` is a JSON array, so each element can be its own
  # placeholder — a single one could not be split back into two at render time.
  secretNames = [ "private-key" "preshared-key" "address-v4" "address-v6" ];

  # Marker, secret name and the splice itself — shared with the NixOS module,
  # which now renders the same way.
  render = import ../../lib/sing-box/render.nix;

  hostArgs = {
    wireguardAddresses = [
      config.sops.placeholder.${secret "address-v4"}
      config.sops.placeholder.${secret "address-v6"}
    ];
    privateKey = config.sops.placeholder.${secret "private-key"};
    presharedKey = config.sops.placeholder.${secret "preshared-key"};
  };

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
    ~/.sing-box/{personal,corp}.json. Requires
    `wireguard/<hostname>/{private-key,preshared-key,address-v4,address-v6}` and
    `sing-box/proxy-outbounds` in secrets.yaml — refresh the latter with
    `just refresh-sing-box-subscription`
  '';

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs (map secret secretNames ++ [ render.proxySecret ]) (_: { });

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
  };
}
