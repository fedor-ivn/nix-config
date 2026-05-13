# User configuration module
{ config, lib, flake, ... }:
{
  options = {
    me = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Your username as shown by `id -un`";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        description = "Your full name for use in Git config";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Your email for use in Git config";
      };
      isMainMachine = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this Home Manager config is evaluated for the main machine";
      };
      sshPublicKey = lib.mkOption {
        type = lib.types.str;
        description = "Your SSH public key for use in authorized_keys";
      };

      ai = {
        skills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.oneOf [ lib.types.path lib.types.str ]);
          readOnly = true;
          description = "Shared AI assistant skills consumed by claude-code and opencode";
        };
        commands = lib.mkOption {
          type = lib.types.attrsOf (lib.types.oneOf [ lib.types.path lib.types.str ]);
          readOnly = true;
          description = "Shared AI assistant commands consumed by claude-code and opencode";
        };
      };
    };
  };

  config = {
    me.ai = {
      skills = {
        # Notion (uncomment when notion-plugin flake input is enabled)
        # "notion/knowledge-capture" = "${flake.inputs.notion-plugin}/skills/notion/knowledge-capture";
        # "notion/meeting-intelligence" = "${flake.inputs.notion-plugin}/skills/notion/meeting-intelligence";
        # "notion/research-documentation" = "${flake.inputs.notion-plugin}/skills/notion/research-documentation";
        # "notion/spec-to-implementation" = "${flake.inputs.notion-plugin}/skills/notion/spec-to-implementation";

        # GWS
        "gws-shared" = "${flake.inputs.gws}/skills/gws-shared";
        "gws-drive" = "${flake.inputs.gws}/skills/gws-drive";
        "gws-drive-upload" = "${flake.inputs.gws}/skills/gws-drive-upload";
        "gws-gmail" = "${flake.inputs.gws}/skills/gws-gmail";
        "gws-gmail-send" = "${flake.inputs.gws}/skills/gws-gmail-send";
        "gws-gmail-triage" = "${flake.inputs.gws}/skills/gws-gmail-triage";
        "gws-gmail-reply" = "${flake.inputs.gws}/skills/gws-gmail-reply";
        "gws-gmail-reply-all" = "${flake.inputs.gws}/skills/gws-gmail-reply-all";
        "gws-gmail-forward" = "${flake.inputs.gws}/skills/gws-gmail-forward";
        "gws-gmail-read" = "${flake.inputs.gws}/skills/gws-gmail-read";
        "gws-gmail-watch" = "${flake.inputs.gws}/skills/gws-gmail-watch";
        "gws-calendar" = "${flake.inputs.gws}/skills/gws-calendar";
        "gws-calendar-insert" = "${flake.inputs.gws}/skills/gws-calendar-insert";
        "gws-calendar-agenda" = "${flake.inputs.gws}/skills/gws-calendar-agenda";

        # Agentic Kit
        "crazy" = "${flake.inputs.agentic-kit}/skills/crazy";

        # Caveman
        "caveman" = "${flake.inputs.caveman}/skills/caveman";

        # Local
        "commit-message" = ./agents/skills/commit-message;
        "create-event" = ./agents/skills/create-event;
        "cv-eval" = ./agents/skills/cv-eval;
      };

      commands = {
        # Notion (uncomment when notion-plugin flake input is enabled)
        # "create-database-row" = "${flake.inputs.notion-plugin}/commands/create-database-row.md";
        # "create-page" = "${flake.inputs.notion-plugin}/commands/create-page.md";
        # "create-task" = "${flake.inputs.notion-plugin}/commands/create-task.md";
        # "database-query" = "${flake.inputs.notion-plugin}/commands/database-query.md";
        # "find" = "${flake.inputs.notion-plugin}/commands/find.md";
        # "search" = "${flake.inputs.notion-plugin}/commands/search.md";
        # "tasks/build" = "${flake.inputs.notion-plugin}/commands/tasks/build.md";
        # "tasks/explain-diff" = "${flake.inputs.notion-plugin}/commands/tasks/explain-diff.md";
        # "tasks/plan" = "${flake.inputs.notion-plugin}/commands/tasks/plan.md";
        # "tasks/setup" = "${flake.inputs.notion-plugin}/commands/tasks/setup.md";
      };
    };

    home.username = config.me.username;
    accounts.email.accounts = let realName = config.me.fullname; in {
      Gmail = {
        address = "ivnfedor@gmail.com";
        flavor = "gmail.com";
        inherit realName;
        primary = true; # Mark as primary account

        thunderbird = {
          enable = true;
          settings = id: {
            "mail.smtpserver.smtp_${id}.authMethod" = 10;
            "mail.server.server_${id}.authMethod" = 10;
          };
        };
      };

      Blockscout = {
        address = "fedor@blockscout.com";
        flavor = "gmail.com";
        inherit realName;

        thunderbird = {
          enable = true;
          settings = id: {
            "mail.smtpserver.smtp_${id}.authMethod" = 10;
            "mail.server.server_${id}.authMethod" = 10;
          };
        };
      };
    };
  };
}
