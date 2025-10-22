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
      urgency.user.tag.today.coefficient = 6;
      context = {
        upcoming = "project.not:shopping project.not:wishlist";
        personal = "project.not:shopping project.not:wishlist project.not:blockscout";
        blockscout = "project:blockscout";
        shop = "project:shopping";
        someday = "(project:wishlist or +someday)";
        today = "(scheduled:today or due.before:tomorrow or due:tomorrow or +today)";
      };
    };
  };
}
