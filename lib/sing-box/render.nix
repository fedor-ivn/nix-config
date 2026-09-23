# Shared plumbing between the two consumers of ./default.nix.
#
# Both hosts now run the same shape — subscription nodes as the default exit,
# `wg` demoted to peer traffic — so the mechanics of getting the nodes out of
# sops and into the config live here instead of being written twice.
#
# Both render a *complete* JSON document through `sops.templates`, rather than
# handing an attrset to a module that substitutes secrets itself. That is forced
# by the shape of the secret: the nodes are a JSON **array of objects**, and
# neither substitution mechanism can produce one.
#
#   * home-manager/darwin never could — `sops.placeholder` is a string.
#   * NixOS `services.sing-box.settings` cannot either: its `{ _secret = path; }`
#     attrsets go through `genJqSecretsReplacementSnippet`, which substitutes
#     *string values*. An `outbounds` element would come out as `"{...}"`.
#
# So both go through `render` below, which splices at the text level. On NixOS
# that means leaving `services.sing-box.settings` empty, which makes the module
# run `sing-box -C $CONFIGURATION_DIRECTORY` (/etc/sing-box) instead of
# rendering its own config — see modules/nixos/sing-box.nix.
rec {
  # Where the nodes live in secrets.yaml. Not per-host: both machines dial the
  # same subscription. Refresh with `just refresh-sing-box-subscription`.
  proxySecret = "sing-box/proxy-outbounds";

  # Stand-in for the node array inside the generator's `outbounds`. It has to
  # survive `builtins.toJSON` unchanged, so it is a plain string.
  marker = "@@PROXY_OUTBOUNDS@@";

  # `sops.placeholder` is a string, but the nodes are a JSON *array* — there is
  # no way to say "expand to several array elements" through `toJSON`. So the
  # marker goes in as a list element, `toJSON` renders it as `"@@...@@"`, and
  # the quotes are stripped along with it here. At activation sops-nix replaces
  # the placeholder with the secret's raw text: the outbound objects
  # comma-separated *without* enclosing brackets, which lands as valid JSON.
  #
  # `placeholders` is `config.sops.placeholder` from whichever module is calling
  # (the option exists on both the NixOS and home-manager sides of sops-nix).
  render = { placeholders, generator, args }:
    builtins.replaceStrings
      [ "\"${marker}\"" ]
      [ placeholders.${proxySecret} ]
      (builtins.toJSON (import generator (args // { proxyOutbounds = marker; })));

  # The same document with dummy values in place of every secret, for a
  # build-time `sing-box check`. The real config is only assembled at
  # activation, so this is the only point where a schema mistake is catchable
  # before it reaches a running service — and `check` is cheap.
  #
  # The dummy nodes stand in for the subscription: two outbounds plus the
  # `proxy-auto`/`proxy` groups the refresh recipe writes, so the generator's
  # references to `proxy` resolve exactly as they will in production.
  checkable = { generator, args }:
    let
      dummyKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      dummyNodes = [
        { type = "socks"; tag = "dummy-a"; server = "127.0.0.1"; server_port = 1080; }
        { type = "socks"; tag = "dummy-b"; server = "127.0.0.1"; server_port = 1081; }
        {
          type = "urltest";
          tag = "proxy-auto";
          outbounds = [ "dummy-a" "dummy-b" ];
        }
        {
          type = "selector";
          tag = "proxy";
          outbounds = [ "proxy-auto" "wg" "direct" "dummy-a" "dummy-b" ];
          default = "proxy-auto";
        }
      ];
      rendered = builtins.toJSON (import generator (args // {
        proxyOutbounds = marker;
        privateKey = dummyKey;
        presharedKey = dummyKey;
        wireguardAddresses = [ "10.0.0.1/32" "fd00::1/128" ];
      }));
      nodesJson = builtins.toJSON dummyNodes;
      # Strip the array's own brackets: the marker sits *inside* `outbounds`.
      inner = builtins.substring 1 (builtins.stringLength nodesJson - 2) nodesJson;
    in
    builtins.replaceStrings [ "\"${marker}\"" ] [ inner ] rendered;
}
