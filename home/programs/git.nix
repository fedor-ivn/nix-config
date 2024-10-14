{
  programs.git = {
    enable = true;
    userEmail = "ivnfedor@gmail.com";
    userName = "Fedor Ivanov";
    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILycRbR32YtN1cD0SkJOwwO1cZgpaKVjJs42nTNh2RCD ivnfedor@gmail.com";

      push = {
        followTags = true;
        autoSetupRemote = true;
      };

      help.autocorrect = 1;

      # Speed up commands involving untracked files such as `git status`.
      # https://git-scm.com/docs/git-update-index#_untracked_cache
      core.untrackedCache = true;

      color.ui = "auto";
    };

    ignores = [
      ".direnv"
      ".envrc"
    ];

    aliases = {
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
}
