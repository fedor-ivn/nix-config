# sing-box split-tunnel router, NixOS flavour.
#
# Same generator *and* the same rendering path as the mac (lib/sing-box,
# lib/sing-box/render.nix); only the delivery differs — a system daemon here, a
# GUI app there. Both hosts run the same shape: subscription nodes as the
# default exit.
#
# `services.sing-box.settings` is deliberately left empty. It used to carry the
# config as an attrset with `{ _secret = <path>; }` leaves, which the nixpkgs
# module substitutes at preStart via genJqSecretsReplacementSnippet — but that
# mechanism substitutes *string values*, and the subscription nodes are an array
# of objects, so it cannot express them (see lib/sing-box/render.nix). With
# `settings = { }` the module's ExecStart switches from RUNTIME_DIRECTORY to
# CONFIGURATION_DIRECTORY, i.e. `sing-box -C /etc/sing-box run`, so we drop a
# sops-rendered config in there instead. The node credentials still never touch
# the Nix store: the rendered file lives under /run/secrets and /etc/sing-box/ only
# symlinks it.
#
# The corp overlay is deliberately not used here: no host running this needs the
# reverse-SSH SOCKS bridge.
#
# The toggle is top-level `singBox`, not `programs.singBox` as on the mac: here it
# is a system daemon routing the whole host, not something the user runs.
{ flake, config, lib, pkgs, ... }:
let
  inherit (flake) inputs;
  cfg = config.singBox;

  render = import ../../lib/sing-box/render.nix;

  hostArgs = {
    # `system` beats gvisor on Linux, and strict_route installs firewall rules
    # that can cut off inbound connections to a box that serves them (SSH,
    # Tailscale) — plain auto_route already keeps LAN/tailnet routes, which are
    # more specific than the tun default route.
    tunStack = "system";
    tunStrictRoute = false;
    tunInterfaceName = "sbtun0";

    # `directDns` is left at the generator's default (an upstream, not
    # `type = "local"`) — systemd-resolved on 127.0.0.53 would loop through the
    # tun exactly as the macOS resolver does. See lib/sing-box/default.nix.

    # `proxyOutbounds` is supplied by render.nix, which owns the marker.
  };

  # The account whose sops age key decrypts secrets.yaml (one entry in practice).
  ageKeyFile =
    "${config.users.users.${lib.head config.managedUsers}.home}/.config/sops/age/keys.txt";

  # Catch schema mistakes at build time, against the very binary that will run
  # this config. Note `check` validates shape only — a detour to an empty direct
  # outbound passes here and is fatal at start.
  configCheck = pkgs.runCommand "sing-box-config-check"
    {
      nativeBuildInputs = [ pkgs.sing-box ];
      configJson = render.checkable {
        generator = ../../lib/sing-box;
        args = hostArgs;
      };
      passAsFile = [ "configJson" ];
    } ''
    sing-box check -c "$configJsonPath"
    touch $out
  '';
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.singBox.enable = lib.mkEnableOption ''
    the sing-box split-tunnel router, reading the subscription nodes from
    `sing-box/proxy-outbounds` in secrets.yaml (refresh it with
    `just refresh-sing-box-subscription`).

    Everything that is not RU-inside, private or tailnet leaves through the
    subscription. There is no WireGuard leg, so 10.6.6.0/24 is unreachable
  '';

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets.yaml;
      # secrets.yaml has exactly one age recipient, and its private half is
      # already on this host at the location home-manager uses (see
      # configurations/home/default.nix) — so read that rather than keep a
      # second root-owned copy in sync. sops-install-secrets runs as root after
      # local-fs.target, so the 0600 file in /home is both mounted and readable.
      age = {
        keyFile = ageKeyFile;
        # The host SSH key is not a recipient; don't let sops-nix add it as one.
        sshKeyPaths = [ ];
      };
      secrets.${render.proxySecret}.restartUnits = [ "sing-box.service" ];

      # The service runs as the `sing-box` user, so it must be able to read the
      # rendered config; the default is root-only.
      templates."sing-box.json" = {
        content = render.render {
          placeholders = config.sops.placeholder;
          generator = ../../lib/sing-box;
          args = hostArgs;
        };
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

    system.extraDependencies = [ configCheck ];
  };
}
