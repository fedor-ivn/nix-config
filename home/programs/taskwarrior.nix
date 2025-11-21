{ config, pkgs, lib, ... }:

{
  sops.secrets = { 
    "taskwarrior-sync/server-url" = { };
    "taskwarrior-sync/client-id" = { };
    "taskwarrior-sync/encryption-secret" = { };
  };
  
  sops.templates."taskwarrior-sync.rc".content = ''
    sync.server.url=${config.sops.placeholder."taskwarrior-sync/server-url"}
    sync.server.client_id=${config.sops.placeholder."taskwarrior-sync/client-id"}
    sync.encryption_secret=${config.sops.placeholder."taskwarrior-sync/encryption-secret"}
  '';
  
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    extraConfig = "include ${config.sops.templates."taskwarrior-sync.rc".path}";
    config = {
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
        today = "(scheduled.before:today or scheduled:today or due.before:tomorrow or due:tomorrow or +today)";
      };
    };
  };
}
