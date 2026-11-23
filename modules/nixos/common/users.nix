# OS accounts managed on a host, plus their home-manager configuration.
{ flake, pkgs, lib, config, ... }:
let
  inherit (flake.inputs) self;
  identity = import ../../../lib/identity.nix;
  mapListToAttrs = m: f:
    lib.listToAttrs (map (name: { inherit name; value = f name; }) m);

  # Extra keys every managed account accepts, from the private flake so no
  # machine's key lands in the public repo. Currently the corp bridge's
  # automation key: the corp Mac reverse-forwards into the homelab and the Mac
  # dials back into the corp Mac, and both directions are unattended, so both
  # are fail-closed on a key that cannot be in this repo.
  #
  # Deliberately *not* `identity.sshPublicKey` alone: that is the person's own
  # key, present here for interactive logins and for the builder.
  extraAuthorizedKeys = flake.inputs.secrets.values.corpBridgeKeys;
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
    # `openssh.authorizedKeys` is set for both platforms: the Darwin hosts need
    # it as much as the Linux ones — `macbook-DLQX9KQ54V` is the corp laptop
    # whose sshd the Mac dials back into, and without a key there that dial is
    # impossible. It used to sit inside the `isLinux` branch, which left every
    # Darwin account authorised by hand.
    users.users = mapListToAttrs config.managedUsers (name:
      {
        openssh.authorizedKeys.keys = [ identity.sshPublicKey ] ++ extraAuthorizedKeys;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin
        {
          home = "/Users/${name}";
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
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
