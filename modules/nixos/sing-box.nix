# sing-box split-tunnel router, NixOS flavour.
#
# Same generator as the mac (lib/sing-box), different plumbing: instead of
# rendering JSON through a sops-nix template and importing it into a GUI app,
# this drives `services.sing-box`, whose `settings` is a freeform JSON submodule.
# The WireGuard identity — keys and tunnel addresses alike — is passed as
# `{ _secret = <path>; }` attrsets, which the nixpkgs module substitutes at
# preStart into /run/sing-box/config.json (RuntimeDirectory, 0700, root), so none
# of it enters the Nix store either. That works inside the `address` array too:
# genJqSecretsReplacementSnippet recurses into lists, addressing elements as
# `.endpoints[0].address[0]`.
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

  # Stand-ins of the right shape, used to validate the config at build time; the
  # real values come from sops at runtime.
  dummyKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  dummyAddresses = [ "10.0.0.1/32" "fd00::1/128" ];

  secretPath = name:
    config.sops.secrets."wireguard/${config.networking.hostName}/${name}".path;

  mkSettings = { privateKey, presharedKey, wireguardAddresses }: import ../../lib/sing-box {
    inherit privateKey presharedKey wireguardAddresses;

    # `system` beats gvisor on Linux, and strict_route installs firewall rules
    # that can cut off inbound connections to a box that serves them (SSH,
    # Tailscale) — plain auto_route already keeps LAN/tailnet routes, which are
    # more specific than the tun default route.
    tunStack = "system";
    tunStrictRoute = false;
    tunInterfaceName = "sbtun0";

    # Not `type = "local"`: that resolves via systemd-resolved on 127.0.0.53,
    # whose own upstream queries leave through the tun inbound and come back
    # through `hijack-dns` — a loop. Talk to an upstream directly instead.
    #
    # No `detour` here, deliberately. A DNS server with no detour dials with
    # sing-box's own default dialer (common/dialer: `Detour == ""` -> NewDefault),
    # which is exactly what an option-less `direct` outbound does — so since 1.12
    # `detour = "direct"` is a *fatal* error, "detour to an empty direct outbound
    # makes no sense". Note this is not the same as falling through to
    # `route.final`: DNS servers never traverse the route rules, so these queries
    # stay off the tunnel, which is the whole point of `direct-dns`. `sing-box
    # check` does not catch the mistake — it only validates the schema, and the
    # detour is resolved at service start.
    directDns = {
      tag = "direct-dns";
      type = "udp";
      server = "1.1.1.1";
    };

    # nixpkgs ships 1.13.x, which predates the `http_client` rule-set field.
    ruleSetDetourField = "download_detour";
  };

  # The account whose sops age key decrypts secrets.yaml (one entry in practice).
  ageKeyFile =
    "${config.users.users.${lib.head config.managedUsers}.home}/.config/sops/age/keys.txt";

  # Catch schema mistakes at build time — unlike the mac, the binary that will
  # run this config is the one we can validate against.
  configCheck = pkgs.runCommand "sing-box-config-check"
    {
      nativeBuildInputs = [ pkgs.sing-box ];
      configJson = builtins.toJSON (mkSettings {
        privateKey = dummyKey;
        presharedKey = dummyKey;
        wireguardAddresses = dummyAddresses;
      });
      passAsFile = [ "configJson" ];
    } ''
    sing-box check -c "$configJsonPath"
    touch $out
  '';
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.singBox.enable = lib.mkEnableOption ''
    the sing-box split-tunnel router, reading this host's WireGuard identity from
    `wireguard/<hostname>/{private-key,preshared-key,address-v4,address-v6}` in
    secrets.yaml. Leave this off until the host's WireGuard peer exists
    server-side: the tun inbound sends everything but RU-inside destinations to
    the endpoint, so an unprovisioned peer blackholes the host's traffic
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
      secrets = lib.genAttrs
        (map (name: "wireguard/${config.networking.hostName}/${name}")
          [ "private-key" "preshared-key" "address-v4" "address-v6" ])
        (_: { restartUnits = [ "sing-box.service" ]; });
    };

    services.sing-box = {
      enable = true;
      settings = mkSettings {
        privateKey._secret = secretPath "private-key";
        presharedKey._secret = secretPath "preshared-key";
        wireguardAddresses = [
          { _secret = secretPath "address-v4"; }
          { _secret = secretPath "address-v6"; }
        ];
      };
    };

    # Secrets must be on disk before the service reads the config.
    systemd.services.sing-box.after = [ "sops-install-secrets.service" ];

    # Return traffic arrives on the tun interface; sing-box owns its routing.
    networking.firewall.trustedInterfaces = [ "sbtun0" ];

    system.extraDependencies = [ configCheck ];
  };
}
