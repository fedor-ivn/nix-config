# sing-box split-tunnel configs for a personal machine, generated from one source.
#
# The generators live in lib/sing-box: the base (personal) profile and the corp
# overlay, which adds the FakeIP DNS server, the SOCKS outbound and the corp
# route rule. This module only supplies the host-specific parts — where to read
# the host's WireGuard identity from, and the config dialect SFM speaks.
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
# Note: no build-time `sing-box check`. SFM tracks dev-next (1.14.x) while
# nixpkgs lags (1.13.x); validating against the older binary false-rejects valid
# 1.14 fields such as rule_set `http_client`.
{ config, lib, osConfig ? { }, ... }:
let
  cfg = config.programs.singBox;

  # The WireGuard identity is per-host, so the secrets to read follow the machine
  # this account is activating on rather than being hardcoded to one hostname.
  secret = name: "wireguard/${osConfig.networking.hostName}/${name}";

  # `endpoints[0].address` is a JSON array, so each element can be its own
  # placeholder — a single one could not be split back into two at render time.
  secretNames = [ "private-key" "preshared-key" "address-v4" "address-v6" ];

  hostArgs = {
    wireguardAddresses = [
      config.sops.placeholder.${secret "address-v4"}
      config.sops.placeholder.${secret "address-v6"}
    ];
    privateKey = config.sops.placeholder.${secret "private-key"};
    presharedKey = config.sops.placeholder.${secret "preshared-key"};
    # SFM ships 1.14.x, where the rule-set download detour is nested under
    # `http_client`.
    ruleSetDetourField = "http_client";
  };
in
{
  options.programs.singBox.enable = lib.mkEnableOption ''
    user-level sing-box configs for SFM (the GUI app), rendered to
    ~/.sing-box/{personal,corp}.json. Requires
    `wireguard/<hostname>/{private-key,preshared-key,address-v4,address-v6}` in
    secrets.yaml
  '';

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs (map secret secretNames) (_: { });

    sops.templates."sing-box-personal.json".content =
      builtins.toJSON (import ../../lib/sing-box hostArgs);
    sops.templates."sing-box-corp.json".content =
      builtins.toJSON (import ../../lib/sing-box/corp.nix hostArgs);

    home.file.".sing-box/personal.json".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-personal.json".path;
    home.file.".sing-box/corp.json".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-corp.json".path;
  };
}
