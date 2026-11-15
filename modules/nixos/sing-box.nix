# sing-box split-tunnel router, NixOS flavour.
#
# Same profile and the same rendering path as the mac (lib/sing-box); only the
# delivery differs — a system daemon here, a GUI app there.
#
# `services.sing-box.settings` is deliberately left empty. It used to carry the
# config as an attrset with `{ _secret = <path>; }` leaves, which the nixpkgs
# module substitutes at preStart — but that mechanism substitutes *string
# values*, and the subscription nodes are an array of objects, so it cannot
# express them (see lib/sing-box/render.nix). With `settings = { }` the module's
# ExecStart switches to `sing-box -C /etc/sing-box run`, so we drop a
# sops-rendered config in there instead. The node credentials still never touch
# the Nix store: the rendered file lives under /run/secrets and /etc/sing-box
# only symlinks it.
#
# The corp profile is not used here: no host running this needs the reverse-SSH
# SOCKS bridge.
#
# The toggle is top-level `singBox`, not `programs.singBox` as on the mac: here
# it is a system daemon routing the whole host, not something the user runs.
{ flake, config, lib, pkgs, ... }:
let
  inherit (flake) inputs;
  cfg = config.singBox;

  singBox = import ../../lib/sing-box;
  inherit (singBox) render;

  profile = render.mkProfile {
    inherit pkgs;
    placeholders = config.sops.placeholder;
    name = "homelab";
    profile = singBox.profiles.personal;
    args = {
      inherit lib;
      platform = "nixos";
    };
  };
in
{
  # Where the age key and secrets.yaml are declared. Imported rather than spelled
  # out here so the host keeps its ability to decrypt when this module is off.
  imports = [ inputs.self.nixosModules.sops ];

  options.singBox.enable = lib.mkEnableOption ''
    the sing-box split-tunnel router, reading the subscription nodes from
    `sing-box/proxy-outbounds` in secrets.yaml (refresh it with
    `just refresh-sing-box-subscription`).

    Everything that is not RU-inside, private or tailnet leaves through the
    subscription. There is no WireGuard leg, so 10.6.6.0/24 is unreachable
  '';

  config = lib.mkIf cfg.enable {
    sops = {
      secrets.${render.proxySecret}.restartUnits = [ "sing-box.service" ];

      # The service runs as the `sing-box` user, so it must be able to read the
      # rendered config; the default is root-only.
      templates."sing-box.json" = {
        content = profile.content;
        owner = "sing-box";
        restartUnits = [ "sing-box.service" ];
      };
    };

    # Empty `settings` makes the module run `sing-box -C $CONFIGURATION_DIRECTORY`
    # (/etc/sing-box) rather than rendering its own config — see the header.
    services.sing-box.enable = true;

    environment.etc."sing-box/config.json".source =
      config.sops.templates."sing-box.json".path;

    # Secrets must be on disk before the service reads the config.
    systemd.services.sing-box.after = [ "sops-install-secrets.service" ];

    # Return traffic arrives on the tun interface; sing-box owns its routing.
    networking.firewall.trustedInterfaces = [ "sbtun0" ];

    system.extraDependencies = [ profile.check ];
  };
}
