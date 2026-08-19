# Base sing-box split-tunnel config generator (personal profile).
#
# Returns an *attrset*, not JSON, so both consumers can use it:
#   * darwin/home-manager renders it with `builtins.toJSON` into a sops-nix
#     template (secrets are `config.sops.placeholder."..."` strings);
#   * NixOS passes it straight to `services.sing-box.settings`, where secrets are
#     `{ _secret = "/run/secrets/..."; }` attrsets that the module substitutes
#     into /run/sing-box/config.json at preStart.
#
# The shape is: everything outside the tunnel that should stay outside (RU-only
# sites by rule-set, private IPs), everything else through the WireGuard
# endpoint. Profiles that need more than this patch the returned attrset — see
# ./corp.nix.
#
# `wireguardAddresses` is the host's addresses inside the tunnel: a two-element
# list (v4, v6). Its elements are secrets too, so each is whatever the consumer's
# substitution mechanism expects — a placeholder string or `{ _secret = ...; }`.
{ wireguardAddresses
, privateKey
, presharedKey
, tunStack ? "gvisor"
, tunStrictRoute ? true
, tunInterfaceName ? null
  # How the host resolves names that must not go through the tunnel (RU-inside
  # rule-set, the WireGuard peer, rule-set downloads). `type = "local"` defers to
  # the system resolver, which is right on macOS but loops on hosts where the
  # stub resolver's own upstream queries get hijacked by the tun inbound.
, directDns ? { tag = "direct-dns"; type = "local"; }
  # Rule-set download detour moved from `download_detour` to `http_client.detour`
  # in sing-box 1.14; pick whichever the target binary understands.
, ruleSetDetourField ? "http_client"
}:
let
  ruleSet = tag: url:
    {
      type = "remote";
      inherit tag url;
      format = "binary";
      update_interval = "1d";
    } // (
      if ruleSetDetourField == "http_client"
      then { http_client.detour = "direct"; }
      else { download_detour = "direct"; }
    );
in
{
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
      directDns
    ];
    rules = [
      {
        rule_set = "geosite-ru-inside";
        server = directDns.tag;
      }
    ];
    final = "tunnel-dns";
  };

  inbounds = [
    ({
      type = "tun";
      tag = "tun-in";
      # Link-local sink for the tun device itself; nothing outside the host
      # addresses it, so it is the same everywhere.
      address = [
        "172.19.0.1/30"
        "fdfe:dcba:9876::1/126"
      ];
      mtu = 1420;
      auto_route = true;
      strict_route = tunStrictRoute;
      stack = tunStack;
    } // (if tunInterfaceName == null then { } else { interface_name = tunInterfaceName; }))
  ];

  endpoints = [
    {
      type = "wireguard";
      tag = "wg";
      address = wireguardAddresses;
      private_key = privateKey;
      peers = [
        {
          # The one server every host here dials.
          address = "snejugal.ru";
          port = 51830;
          public_key = "OFp4DTqLQKgBZTN+N2rZ7zscb90kU/kANX34qFv2PjM=";
          pre_shared_key = presharedKey;
          allowed_ips = [
            "0.0.0.0/0"
            "::/0"
          ];
          persistent_keepalive_interval = 16;
        }
      ];
    }
  ];

  outbounds = [
    {
      type = "direct";
      tag = "direct";
    }
  ];

  route = {
    rules = [
      { action = "sniff"; }
      {
        protocol = "dns";
        action = "hijack-dns";
      }
      # Anything below here selects an outbound; ./corp.nix relies on that to
      # insert its own rule ahead of them.
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
    default_domain_resolver = directDns.tag;
  };

  experimental.cache_file.enabled = true;
}
