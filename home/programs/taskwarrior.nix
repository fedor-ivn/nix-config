{ pkgs, ... }:
let
  taskSyncScript = pkgs.writeShellScriptBin "task-sync" ''
    #!/usr/bin/env bash
    task sync > /dev/null
  '';
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
      uda.taskwarrior-tui.shortcuts."1" = "${taskSyncScript}/bin/task-sync";
    };
  };

  home.packages = [ taskSyncScript ];
}
