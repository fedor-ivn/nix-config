{ flake, ... }:
let
  self = flake.inputs.self;
in
{
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    WindowManager.EnableStandardClickToShowDesktop = false;

    CustomUserPreferences = {
      GlobalPreferences = {
        NSUserDictionaryReplacementItems = map (item: { on = 1; } // item) [
          {
            replace = ">=";
            "with" = "≥";
          }
          {
            replace = "<=";
            "with" = "≤";
          }
          {
            replace = "!=";
            "with" = "≠";
          }
          {
            replace = "->";
            "with" = "→";
          }
          {
            replace = "дy";
            "with" = "доброе утро";
          }
          {
            replace = "есчо";
            "with" = "если что";
          }
          {
            replace = "кмк";
            "with" = "как мне кажется";
          }
          {
            replace = "мб";
            "with" = "может быть";
          }
          {
            replace = "плз";
            "with" = "пожалуйста";
          }
          {
            replace = "сн";
            "with" = "спокойной ночи";
          }
          {
            replace = "спс";
            "with" = "спасибо";
          }
        ];
      };
    };

    finder = {
      CreateDesktop = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      FXDefaultSearchScope = "SCcf";
    };

    dock = {
      mru-spaces = false;
      autohide = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleScrollerPagingBehavior = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleShowScrollBars = "WhenScrolling";
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
      NSDocumentSaveNewDocumentsToCloud = false;
      "com.apple.keyboard.fnState" = true;
    };
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.zsh.enable = true;
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    # Reap dead corp reverse-tunnel sessions promptly so port 2222 is freed for
    # reconnect. Without this the Mac sshd holds zombie sessions until TCP timeout.
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 3
    '';
  };
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
