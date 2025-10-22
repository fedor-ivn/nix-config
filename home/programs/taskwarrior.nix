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
      uda.taskwarrior-tui = {
        shortcuts = {
          "1" = "task-open-urls";
          "2" = "task-sync";
        };
        quick-tag.name = "today";
      };
      context = {
        main = "project.not:shopping";
        personal = "project.not:shopping project.not:blockscout";
        blockscout = "project:blockscout";
        shop = "project:shopping";
        today = "(scheduled:today or due.before:tomorrow or due:tomorrow or +today)";
      };
    };
  };
}
