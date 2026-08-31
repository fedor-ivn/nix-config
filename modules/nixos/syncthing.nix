# Syncthing, NixOS flavour: system service syncing only the Sync folder
# against the other devices in lib/syncthing (phone, personal Mac, corp Mac).
{ flake, config, lib, ... }:
let
  inherit (flake) inputs;
  cfg = config.syncthing;
  user = lib.head config.managedUsers;
  syncthingLib = import ../../lib/syncthing { secrets = inputs.secrets.values; };
in
{
  options.syncthing.enable = lib.mkEnableOption "Syncthing";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit user;
      dataDir = "/home/${user}/Sync";
      configDir = "/home/${user}/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      openDefaultPorts = true;
      settings = {
        devices = syncthingLib.devices;
        folders.Sync = syncthingLib.mkSyncFolder {
          path = "/home/${user}/Sync";
          devices = builtins.attrNames syncthingLib.devices;
        };
      };
    };
  };
}
