{ pkgs, ... }:
let
  secrets = import ../../secrets/taskwarrior-sync.nix;
in
{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      sync.server.url = secrets.syncUrl;
      sync.server.client_id = secrets.clientId;
      sync.encryption_secret = secrets.encryptionSecret;
      recurrence = "on";
      uda.taskwarrior-tui.shortcuts."1" = "task-open-urls";
      uda.taskwarrior-tui.shortcuts."2" = "task-sync";
    };
  };
}
