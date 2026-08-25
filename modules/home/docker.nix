{ config, lib, ... }:
let
  cfg = config.programs.dockerConfig;
in
{
  # Declarative ~/.docker/config.json. Other modules contribute `credHelpers`
  # and `auths` entries, so each registry stays with whoever owns it (e.g. the
  # private nix-secrets adds the corp artifactory hosts).
  options.programs.dockerConfig = {
    enable = lib.mkEnableOption "declarative ~/.docker/config.json";

    credHelpers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = { "ghcr.io" = "osxkeychain"; };
      description = ''
        Registry host -> helper suffix. Docker runs `docker-credential-<suffix>`
        from PATH to fetch credentials for that host.
      '';
    };

    auths = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      example = lib.literalExpression ''
        { "ghcr.io".username = "me"; "ghcr.io".password = "..."; }
      '';
      description = ''
        Static `auths` entries. Values may be `config.sops.placeholder."..."`:
        the file is rendered through a sops template, so nothing lands in the
        Nix store. Docker reads `username`/`password` verbatim when `auth` is
        absent, so no base64 blob is needed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Rendered by sops even when no placeholders are used — one code path, and
    # the file never becomes world-readable in /nix/store.
    sops.templates."docker-config.json" = {
      mode = "0600";
      content = builtins.toJSON { inherit (cfg) auths credHelpers; };
    };

    home.file.".docker/config.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."docker-config.json".path;
  };
}
