# sing-box split-tunnel configs, generated from one source.
#
# Two profiles share a single `mkConfig` generator; the `corp` flag toggles the
# only parts that differ (FakeIP DNS rule, the SOCKS outbound, and the corp
# route rule). Both profiles are rendered by sops-nix at *activation* time, so
# the WireGuard keys never enter the world-readable Nix store — they live in
# secrets.yaml under `wireguard/{private-key,preshared-key}` and are
# interpolated via placeholders.
#
# The rendered files are symlinked into ~/.sing-box/{personal,corp}.json (out of
# store), which you import into SFM. Pick `corp.json` when the reverse-SSH SOCKS
# bridge (127.0.0.1:1080) is up, `personal.json` otherwise.
#
# Note: no build-time `sing-box check`. SFM tracks dev-next (1.14.x) while
# nixpkgs lags (1.13.x); validating against the older binary false-rejects
# valid 1.14 fields such as rule_set `http_client`.
{ config, lib, ... }:
let
  corpDomains = [ "tcsbank.ru" "t-tech.team" "tcsgroup.io" "tbank.ru" "tinkoff.ru"];

  ruleSet = tag: url: {
    type = "remote";
    inherit tag url;
    format = "binary";
    http_client.detour = "direct";
    update_interval = "1d";
  };

  mkConfig =
    { corp }:
    builtins.toJSON {
      log = {
        level = "info";
        timestamp = true;
      };

      dns = {
        servers = [
          {
            tag = "tunnel-dns";
            type = "udp";
            server = "1.1.1.1";
            detour = "wg";
          }
          {
            tag = "direct-dns";
            type = "local";
          }
          {
            tag = "fakeip-dns";
            type = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "fc00::/18";
          }
        ];
        rules =
          lib.optionals corp [
            {
              domain_suffix = corpDomains;
              server = "fakeip-dns";
            }
          ]
          ++ [
            {
              rule_set = "geosite-ru-inside";
              server = "direct-dns";
            }
          ];
        final = "tunnel-dns";
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          address = [
            "172.19.0.1/30"
            "fdfe:dcba:9876::1/126"
          ];
          mtu = 1420;
          auto_route = true;
          strict_route = true;
          stack = "gvisor";
        }
      ];

      endpoints = [
        {
          type = "wireguard";
          tag = "wg";
          address = [
            "10.6.6.17/32"
            "fd9f:6666::f/128"
          ];
          private_key = config.sops.placeholder."wireguard/private-key";
          peers = [
            {
              address = "snejugal.ru";
              port = 51830;
              public_key = "OFp4DTqLQKgBZTN+N2rZ7zscb90kU/kANX34qFv2PjM=";
              pre_shared_key = config.sops.placeholder."wireguard/preshared-key";
              allowed_ips = [
                "0.0.0.0/0"
                "::/0"
              ];
              persistent_keepalive_interval = 16;
            }
          ];
        }
      ];

      outbounds =
        [
          {
            type = "direct";
            tag = "direct";
          }
        ]
        ++ lib.optionals corp [
          {
            type = "socks";
            tag = "socks-tbank";
            server = "127.0.0.1";
            server_port = 1080;
            version = "5";
          }
        ];

      route = {
        rules =
          [
            { action = "sniff"; }
            {
              protocol = "dns";
              action = "hijack-dns";
            }
          ]
          ++ lib.optionals corp [
            {
              domain_suffix = corpDomains;
              outbound = "socks-tbank";
            }
          ]
          ++ [
            {
              rule_set = [
                "geosite-ru-inside"
                "geoip-ru"
              ];
              outbound = "direct";
            }
            {
              ip_is_private = true;
              outbound = "direct";
            }
          ];
        rule_set = [
          (ruleSet "geosite-ru-inside"
            "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geosite/geosite-ru-available-only-inside.srs"
          )
          (ruleSet "geoip-ru"
            "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geoip/geoip-ru.srs"
          )
        ];
        final = "wg";
        auto_detect_interface = true;
        default_domain_resolver = "direct-dns";
      };

      experimental.cache_file.enabled = true;
    };
in
{
  config = lib.mkIf config.me.isMainMachine {
    sops.secrets = {
      "wireguard/private-key" = { };
      "wireguard/preshared-key" = { };
    };

    sops.templates."sing-box-personal.json".content = mkConfig { corp = false; };
    sops.templates."sing-box-corp.json".content = mkConfig { corp = true; };

    home.file.".sing-box/personal.json".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-personal.json".path;
    home.file.".sing-box/corp.json".source =
      config.lib.file.mkOutOfStoreSymlink config.sops.templates."sing-box-corp.json".path;
  };
}
