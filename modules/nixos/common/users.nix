# OS accounts managed on a host, plus their home-manager configuration.
{ flake, pkgs, lib, config, ... }:
let
  inherit (flake.inputs) self;
  identity = import ../../../lib/identity.nix;
  mapListToAttrs = m: f:
    lib.listToAttrs (map (name: { inherit name; value = f name; }) m);
in
{
  options = {
    managedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        OS account usernames to create on this host and manage with
        home-manager. Each account shares the same generic home config
        (configurations/home) and identity (lib/identity.nix); only the
        username differs.
      '';
      default = [ "fedorivn" ];
    };
  };

  config = {
    # For home-manager to work.
    # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
    users.users = mapListToAttrs config.managedUsers (name:
      lib.optionalAttrs pkgs.stdenv.isDarwin
        {
          home = "/Users/${name}";
        } // lib.optionalAttrs pkgs.stdenv.isLinux {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        openssh.authorizedKeys.keys = [ identity.sshPublicKey ];
      }
    );

    # Enable home-manager for each managed account, injecting its username.
    home-manager.users = mapListToAttrs config.managedUsers (name: {
      imports = [ (self + /configurations/home) ];
      me.username = name;
    });

    # All users can add Nix caches.
    nix.settings.trusted-users = [
      "root"
    ] ++ config.managedUsers;
  };
}
