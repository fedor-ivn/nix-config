# Host-level sops-nix wiring: the upstream module, where the encrypted file is
# and which key opens it. Nothing service-specific — a module that needs a
# secret imports this one and declares only its own `sops.secrets` /
# `sops.templates`.
#
# This is the system-side mirror of the `sops` block in
# configurations/home/default.nix, which does the same for every managed
# account. Both halves read the *same* age key, so a host whose home-manager
# config decrypts secrets.yaml decrypts it as root too.
#
# It lives apart from its consumers so that disabling a service cannot take the
# host's ability to decrypt with it.
{ flake, config, lib, ... }:
let
  inherit (flake) inputs;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;

    # secrets.yaml has exactly one age recipient, and its private half is
    # already on this host at the location home-manager uses (see
    # configurations/home/default.nix) — so read that rather than keep a second
    # root-owned copy in sync. sops-install-secrets runs as root after
    # local-fs.target, so the 0600 file in /home is both mounted and readable.
    age = {
      # The account whose age key decrypts secrets.yaml (one in practice).
      keyFile =
        "${config.users.users.${lib.head config.managedUsers}.home}/.config/sops/age/keys.txt";

      # The host SSH key is not a recipient; don't let sops-nix add it as one.
      sshKeyPaths = [ ];
    };
  };
}
