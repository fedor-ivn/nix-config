# Syncthing, NixOS flavour: system service syncing only the Documents folder
# against the other devices in lib/syncthing (phone, personal Mac, corp Mac).
{ flake, config, lib, ... }:
let
  inherit (flake) inputs;
  cfg = config.syncthing;
  user = lib.head config.managedUsers;
  syncthingLib = import ../../lib/syncthing { secrets = inputs.secrets.values; };
in
{
  options.syncthing.enable = lib.mkEnableOption "Syncthing (Documents folder only)";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit user;
      dataDir = "/home/${user}/Documents";
      configDir = "/home/${user}/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = syncthingLib.devices;
        folders.Documents = syncthingLib.mkDocumentsFolder {
          path = "/home/${user}/Documents";
          devices = builtins.attrNames syncthingLib.devices;
        };
      };
    };
  };
}
