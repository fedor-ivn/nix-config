{ config, pkgs, ... }:

let
  sync = pkgs.writeShellScriptBin "task-sync" ''
    task sync > /dev/null
  '';

  tagNext = pkgs.writeShellScriptBin "task-tag-next" ''
    [ -n "$1" ] || { echo "Usage: task-tag-next <id>"; exit 1; }
    task rc.verbose= "$1" modify +next
  '';

  tickle = pkgs.writeShellScriptBin "tick" ''
    [ -n "$1" ] || { echo "Usage: tick <date> [description...]"; exit 1; }
    deadline=$1
    shift
    task rc.verbose= add wait:"$deadline" "$@"
  '';

  buy = pkgs.writeShellScriptBin "buy" ''
    task rc.verbose= add project:shopping "$@"
  '';

  openUrls = pkgs.writeShellApplication {
    name = "task-open-urls";
    runtimeInputs = with pkgs; [ jq taskwarrior3 ];
    text = ''
      if [ $# -ne 1 ]; then
        echo "Usage: $0 TASK_ID"
        exit 1
      fi

      TASK_ID="$1"

      if command -v xdg-open &>/dev/null; then
        OPENER="xdg-open"
      elif command -v open &>/dev/null; then
        OPENER="open"
      else
        echo "Error: Could not find 'xdg-open' or 'open' to launch URLs." >&2
        exit 1
      fi

      URLS=$(task "$TASK_ID" export \
        | jq -r '.[0].annotations[].description' \
        | grep -Eo '[a-z][a-z0-9+.-]*://[^[:space:]]+' \
        || true)

      if [ -z "$URLS" ]; then
        echo "No URLs found in annotations for task $TASK_ID."
        exit 0
      fi

      echo "Opening URLs for task $TASK_ID:"
      while IFS= read -r url; do
        echo " ↳ $url"
        $OPENER "$url" &
      done <<< "$URLS"
    '';
  };

in
{
  config = {
    home = {
      packages = [ pkgs.taskwarrior-tui sync openUrls tagNext buy tickle ];
      shellAliases = {
        t = "task";
        tt = "taskwarrior-tui";
      };
    };

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
      config =
        {
          default.project = "inbox";
          uda.taskwarrior-tui = {
            shortcuts = {
              "1" = "task-open-urls";
              "2" = "task-sync";
              "5" = "task-tag-next";
            };
            quick-tag.name = "today";
            keyconfig.shortcut5="n";
          };
          urgency.user.tag.today.coefficient = 6;
          context = {
            inbox = "project:inbox";
            personal = "project.not:shopping project.not:inbox -sdm";
            shop = "project:shopping -sdm";
            someday = "+sdm";
            today = "(scheduled.before:today or scheduled:today or due.before:tomorrow or due:tomorrow or +today)";
          };
          recurrence = if config.me.isMainMachine then "on" else "off";
        };
    };
  };
}
