{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;

  taskSync = pkgs.writeShellScriptBin "task-sync" ''
    #!/usr/bin/env bash
    task sync > /dev/null
  '';

  taskImportGh = pkgs.writeShellApplication {
    name = "gh-task";
    runtimeInputs = with pkgs; [ gh jq ];
    text = ''
      # A script to convert GitHub PRs to Taskwarrior tasks using task import

      set -euo pipefail

      if [ $# -lt 1 ]; then
        echo "Usage: $(basename "$0") PR_URL [project]"
        echo "Example: $(basename "$0") https://github.com/blockscout/blockscout/pull/12242 [blockscout]"
        exit 1
      fi

      PR_URL="$1"
      PROJECT="''${2:-$(echo "$PR_URL" | cut -d'/' -f4)}"

      # Extract repo and PR number from URL
      REPO_OWNER=$(echo "$PR_URL" | cut -d'/' -f4)
      REPO_NAME=$(echo "$PR_URL" | cut -d'/' -f5)
      PR_NUMBER=$(echo "$PR_URL" | cut -d'/' -f7)

      # Fetch PR details using gh CLI
      echo "Fetching PR information for $PR_URL..."
      PR_DATA=$(gh pr view "$PR_NUMBER" --repo "$REPO_OWNER/$REPO_NAME" --json title,url,number)

      # Extract PR title and URL using jq
      PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
      PR_URL=$(echo "$PR_DATA" | jq -r '.url')
      PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number')

      # Extract the tag/prefix from the PR title (conventional commit format)
      TAG=$(echo "$PR_TITLE" | grep -oP '^(\w+)(?=:)' || echo "misc")
      TAG="''${TAG,,}" # Convert to lowercase

      # Clean the task title (remove the prefix) and capitalize first letter
      TASK_TITLE=$(echo "$PR_TITLE" | sed -E 's/^[a-zA-Z]+: *//')
      # Capitalize first letter
      TASK_TITLE=$(echo "$TASK_TITLE" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

      # Get current timestamp
      TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

      # Create a temporary JSON file for task import
      TEMP_JSON=$(mktemp)

      # Create JSON structure for task import
      cat > "$TEMP_JSON" << EOF
      [
        {
          "description": "$TASK_TITLE",
          "project": "$PROJECT",
          "tags": ["$TAG"],
          "annotations": [
            {
              "description": "$PR_URL",
              "entry": "$TIMESTAMP"
            }
          ]
        }
      ]
      EOF

      # Import the task
      echo "Importing Taskwarrior task..."
      IMPORT_RESULT=$(task import "$TEMP_JSON")

      # Extract task ID from import result
      echo "$IMPORT_RESULT"

      # Clean up temp file
      rm "$TEMP_JSON"

      exit 0
    '';
  };

  taskOpenUrls = pkgs.writeShellApplication {
    name = "task-open-urls";
    runtimeInputs = with pkgs; [ jq pkgs.taskwarrior3 ];
    text = ''
      #!/usr/bin/env bash
      #
      # task-open-urls.sh
      # Usage: ./task-open-urls.sh <TASK_ID>
      #

      set -euo pipefail

      if [ $# -ne 1 ]; then
        echo "Usage: $0 TASK_ID"
        exit 1
      fi

      TASK_ID="$1"

      # Determine URL opener
      if command -v xdg-open &>/dev/null; then
        OPENER="xdg-open"
      elif command -v open &>/dev/null; then
        OPENER="open"
      else
        echo "Error: Could not find 'xdg-open' or 'open' to launch URLs." >&2
        exit 1
      fi

      # Fetch the task as JSON, extract annotation descriptions, find URLs of any scheme
      URLS=$(task "$TASK_ID" export \
        | jq -r '.[0].annotations[].description' \
        | grep -Eo '[a-z][a-z0-9+.-]*://[^[:space:]]+' \
        || true)

      if [ -z "$URLS" ]; then
        echo "No URLs found in annotations for task $TASK_ID."
        exit 0
      fi

      # Open each URL
      echo "Opening URLs for task $TASK_ID:"
      while IFS= read -r url; do
        echo " ↳ $url"
        $OPENER "$url" &
      done <<< "$URLS"

      exit 0
    '';
  };

in
{
  config = {
    # Scripts from old shell-applications.nix
    home = {
      packages = [ pkgs.taskwarrior-tui taskSync taskImportGh taskOpenUrls ];
      shellAliases = {
        t = "task";
        tt = "taskwarrior-tui";
      };
    };

    # Taskwarrior configuration from old taskwarrior.nix
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
          uda.taskwarrior-tui = {
            shortcuts = {
              "1" = "task-open-urls";
              "2" = "task-sync";
            };
            quick-tag.name = "today";
          };
          urgency.user.tag.today.coefficient = 6;
          context = {
            upcoming = "project.not:shopping project.not:wishlist -someday";
            personal = "project.not:shopping project.not:wishlist project.not:blockscout -someday";
            blockscout = "project:blockscout -someday";
            shop = "project:shopping -someday";
            someday = "(project:wishlist or +someday)";
            today = "(scheduled.before:today or scheduled:today or due.before:tomorrow or due:tomorrow or +today)";
          };
          recurrence = if config.me.isMainMachine then "on" else "off";
        };
    };
  };
}
