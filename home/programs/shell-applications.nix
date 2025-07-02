{ pkgs, ... }:

let

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
  home.packages = [ taskSync taskImportGh taskOpenUrls ];
}
