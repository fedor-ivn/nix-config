{ config, ... }:
let
  ignores = [
    ".direnv"
    ".envrc"
  ];
  tbankIgnores = ignores ++ [ ".claude" ];
  tbankIgnoreFile = ".config/git/tbank-ignore";
in
{
  home.file.${tbankIgnoreFile}.text =
    builtins.concatStringsSep "\n" tbankIgnores;

  programs = {
    git = {
      enable = true;

      signing = {
        format = "ssh";
        key = "key::${config.me.sshPublicKey}";
        signByDefault = true;
      };

      settings = {
        user = {
          # Prefer dynamic values if available, fall back to literals from old config.
          email = config.me.email or "ivnfedor@gmail.com";
          name = config.me.fullname or "Fedor Ivanov";
        };

        push = {
          followTags = true;
          autoSetupRemote = true;
        };

        help.autocorrect = 1;

        # Speed up commands involving untracked files such as `git status`.
        # https://git-scm.com/docs/git-update-index#_untracked_cache
        core.untrackedCache = true;

        color.ui = "auto";

        commit.aiMessageStyle = "simple";

        alias = {
          sw = "switch";
          # View abbreviated SHA, description, and history graph of the latest 20 commits.
          l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
          c = "commit";
          s = "status";
          a = "add";
          pl = "pull";
          p = "push";
          pf = "push --force";
          # Show the diff between the latest commit and the current state.
          d = ''!"git diff-index --quiet HEAD -- || clear; git --no-pager diff --patch-with-stat"'';
          # List aliases.
          aliases = "config --get-regexp alias";
          # Amend the currently staged files to the latest commit.
          amend = "commit --amend --reuse-message=HEAD";
          branches = "branch --all";
        };
      };

      includes = [
        {
          condition = "hasconfig:remote.*.url:ssh://git@gitlab.tcsbank.ru:*/**";
          contents = {
            user.email = "ext.fivanov@tbank.ru";
            core.excludesFile = "~/${tbankIgnoreFile}";
          };
        }
      ];

      inherit ignores;
    };

    # Preserve lazygit from the new config since it doesn't conflict.
    lazygit.enable = true;
  };

}
