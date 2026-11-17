# Shared plumbing between the two consumers of ./profiles/.
#
# The subscription nodes live in secrets.yaml, never in this repo, so the final
# document cannot be a plain Nix value: it is assembled at activation time by
# sops-nix. This file is that seam — both hosts splice the same secret into the
# same profile and differ only in where the result lands.
#
# The splice replaces a marker *inside* the profile's `outbounds` with the
# secret's raw text. `sing-box merge` would assemble the document from separate
# files at runtime instead, but the secret's format is welded to the splice: a
# profile appends outbounds to that array from nix, and a bracketed array cannot
# be spliced inside it. (NixOS alone could take the merge — the module already
# runs `-C /etc/sing-box` — but macOS cannot: sops-nix renders templates from a
# launchd agent that activation only bootstraps, so a merge step would race the
# render.) Keep the splice.
rec {
  # Where the nodes live in secrets.yaml. Not per-host: both machines dial the
  # same subscription. Refresh with `just refresh-sing-box-subscription`.
  proxySecret = "sing-box/proxy-outbounds";

  # Stand-in for the node array inside the profile's `outbounds`. It has to
  # survive `builtins.toJSON` unchanged, so it is a plain string.
  marker = "@@PROXY_OUTBOUNDS@@";

  # `sops.placeholder` is a string, but the nodes are a JSON *array*. So the
  # marker goes in as a list element, `toJSON` renders it as `"@@...@@"`, and
  # those quotes are stripped along with it here. At activation sops-nix swaps in
  # the secret's raw text: the outbound objects comma-separated *without*
  # enclosing brackets, which lands as valid JSON.
  #
  # `profile` is a function (see ./profiles/), applied here rather than imported
  # from a path, so profiles compose as ordinary values.
  render = { placeholders, profile, args }:
    builtins.replaceStrings
      [ "\"${marker}\"" ]
      [ placeholders.${proxySecret} ]
      (builtins.toJSON (profile (args // { proxyOutbounds = marker; })));

  # The same document with one dummy outbound in place of the nodes, for a
  # build-time `sing-box check`. One object, not an array: the marker is already
  # one element of `outbounds`, and a bracketed value would nest. `check`
  # validates schema only (it does not resolve tags), so one element is enough.
  checkable = { profile, args }:
    builtins.replaceStrings
      [ "\"${marker}\"" ]
      [ ''{ "type": "socks", "tag": "proxy", "server": "127.0.0.1", "server_port": 1080 }'' ]
      (builtins.toJSON (profile (args // { proxyOutbounds = marker; })));

  # Everything both modules need for one profile: the template text for
  # `sops.templates`, and a derivation that schema-checks it so a mistake fails
  # the build instead of the running service. Delivery is the caller's problem —
  # SFM fetches a served file, NixOS reads /etc/sing-box.
  #
  # A profile without the marker (no subscription) is also grepped for `proxy`:
  # that tag is defined only by the spliced-in nodes, and naming it anyway fails
  # at service start while `check`, which does not resolve tags, passes.
  mkProfile = { pkgs, placeholders, name, profile, args }:
    let
      configJson = checkable { inherit profile args; };
      splicesNodes = pkgs.lib.hasInfix "\"${marker}\""
        (builtins.toJSON (profile (args // { proxyOutbounds = marker; })));
    in
    {
      content = render { inherit placeholders profile args; };

      check = pkgs.runCommand "sing-box-check-${name}"
        {
          nativeBuildInputs = [ pkgs.sing-box ];
          inherit configJson;
          passAsFile = [ "configJson" ];
        } (''
        sing-box check -c "$configJsonPath"
      '' + pkgs.lib.optionalString (!splicesNodes) ''
        if grep -q '"proxy"' "$configJsonPath"; then
          echo "sing-box-${name}: names \`proxy\` without the subscription that defines it" >&2
          exit 1
        fi
      '' + ''
        touch $out
      '');
    };
}
