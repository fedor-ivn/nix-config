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
# store), which you import into SFM. Pick `corp.json` when the reverse-SSH SOCKS
# bridge (127.0.0.1:1080) is up, `personal.json` otherwise.
#
# Default traffic leaves through subscription nodes. They are baked in here
# rather than fetched at runtime because sing-box has no subscription support
# and SFM's "remote profile" replaces the *whole* config, which would discard
# the corp/RU routing this module exists for. That is only workable because the
# subscription's output is byte-stable; refresh it with
# `just refresh-sing-box-subscription`. Full reasoning in
# openspec/specs/split-tunnel-router/design-notes.md.
#
# Validated at build time against nixpkgs' sing-box via `lib/sing-box/render.nix`
# `checkable`, which renders the same document with dummy secrets. That used to
# be impossible for two reasons, both now gone: SFM tracked 1.14.x while nixpkgs
# lagged on 1.13.x (both are 1.14 now), and the template is not valid JSON until
# sops substitutes it (hence the dummy-node render).
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
    ~/.sing-box/{personal,corp}.json. Requires `sing-box/proxy-outbounds` in
    secrets.yaml — refresh it with `just refresh-sing-box-subscription`
  '';

  config = lib.mkIf cfg.enable {
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
  };
}
