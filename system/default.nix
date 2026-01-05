{
  config,
  self,
  system,
  pkgs,
  username,
  hostname,
  lib,
  secrets,
  ...
}:
let

  fixAccessibilityScript = pkgs.writeShellScriptBin "fix-accessibility" ''
        #!/bin/bash
        set -e
        
        echo "========================================="
        echo "Fixing skhd and yabai for Accessibility"
        echo "========================================="
        echo ""
        
        # Setup skhd
        echo "Setting up skhd app bundle..."
        SKHD_APP="/Applications/skhd.app"
        sudo mkdir -p "$SKHD_APP/Contents/MacOS"
        sudo cp -f ${pkgs.skhd}/bin/skhd "$SKHD_APP/Contents/MacOS/skhd"
        sudo chmod +x "$SKHD_APP/Contents/MacOS/skhd"
        
        sudo tee "$SKHD_APP/Contents/Info.plist" > /dev/null <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
     "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
      <key>CFBundleIdentifier</key><string>org.nixos.skhd</string>
      <key>CFBundleName</key><string>skhd</string>
      <key>CFBundleExecutable</key><string>skhd</string>
      <key>CFBundleVersion</key><string>1.0.0</string>
      <key>LSUIElement</key><true/>
    </dict></plist>
    EOF
        
        sudo chown -R root:wheel "$SKHD_APP"
        echo "✓ skhd app bundle created"
        
        # Setup yabai
        echo "Setting up yabai app bundle..."
        YABAI_APP="/Applications/yabai.app"
        sudo mkdir -p "$YABAI_APP/Contents/MacOS"
        sudo cp -f ${pkgs.yabai}/bin/yabai "$YABAI_APP/Contents/MacOS/yabai"
        sudo chmod +x "$YABAI_APP/Contents/MacOS/yabai"
        
        sudo tee "$YABAI_APP/Contents/Info.plist" > /dev/null <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
     "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
      <key>CFBundleIdentifier</key><string>org.nixos.yabai</string>
      <key>CFBundleName</key><string>yabai</string>
      <key>CFBundleExecutable</key><string>yabai</string>
      <key>CFBundleVersion</key><string>1.0.0</string>
      <key>LSUIElement</key><true/>
    </dict></plist>
    EOF
        
        sudo chown -R root:wheel "$YABAI_APP"
        echo "✓ yabai app bundle created"
        echo ""
        
        # Patch plists
        echo "Patching launchd plists..."
        SKHD_PLIST="$HOME/Library/LaunchAgents/org.nixos.skhd.plist"
        YABAI_PLIST="$HOME/Library/LaunchAgents/org.nixos.yabai.plist"
        
        if [ -f "$SKHD_PLIST" ]; then
          echo "Patching $SKHD_PLIST..."
          sed -i.bak 's|<string>.*/bin/skhd</string>|<string>/Applications/skhd.app/Contents/MacOS/skhd</string>|g' "$SKHD_PLIST"
          echo "✓ skhd plist patched"
          
          # Show the result
          echo "New ProgramArguments:"
          grep -A3 "ProgramArguments" "$SKHD_PLIST"
        else
          echo "⚠ $SKHD_PLIST not found"
        fi
        
        echo ""
        
        if [ -f "$YABAI_PLIST" ]; then
          echo "Patching $YABAI_PLIST..."
          sed -i.bak 's|<string>.*/bin/yabai</string>|<string>/Applications/yabai.app/Contents/MacOS/yabai</string>|g' "$YABAI_PLIST"
          echo "✓ yabai plist patched"
          
          # Show the result
          echo "New ProgramArguments:"
          grep -A3 "ProgramArguments" "$YABAI_PLIST"
        else
          echo "⚠ $YABAI_PLIST not found"
        fi
        
        echo ""
        echo "========================================="
        echo "Restarting services..."
        echo "========================================="
        
        # Restart services
        launchctl kickstart -k gui/$(id -u)/org.nixos.skhd 2>/dev/null || echo "Note: skhd might not be running yet"
        launchctl kickstart -k gui/$(id -u)/org.nixos.yabai 2>/dev/null || echo "Note: yabai might not be running yet"
        
        sleep 2
        
        echo ""
        echo "Checking running processes..."
        ps aux | grep -E '(skhd|yabai)' | grep -v grep || echo "No processes found"
        
        echo ""
        echo "========================================="
        echo "✓ Setup complete!"
        echo "========================================="
        echo ""
        echo "Next steps:"
        echo "1. Open System Settings → Privacy & Security → Accessibility"
        echo "2. Grant permission to:"
        echo "   - /Applications/skhd.app"
        echo "   - /Applications/yabai.app"
        echo ""
        echo "If permissions are already granted, remove and re-add them."
        echo ""
        echo "After granting permissions, restart services again:"
        echo "  launchctl kickstart -k gui/\$(id -u)/org.nixos.skhd"
        echo "  launchctl kickstart -k gui/\$(id -u)/org.nixos.yabai"
  '';
in
{
  imports = [
    ./services/yabai.nix
    ./services/skhd.nix
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # darwin.xcode
    htop
    fixAccessibilityScript
  ];

  users.users.fedorivn = {
    name = "fedorivn";
    home = "/Users/fedorivn";
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;
  # system.defaults.dock.autohide-delay = 0.24;
  # system.defaults.dock.autohide-time-modifier = 1.0;

  # TODO: what is that?
  # services.lorri.enable
  # services.jankyborders.enable
  # services.dnsmasq.enable
  # security.sandbox.profiles
  # services.mopidy.enable
  # services.netbird.enable
  #  services.nextdns.enable
  #  services.sketchybar.enable
  #  services.spacebar.enable
  #  services.spotifyd.enable
  #  services.synapse-bt.enable
  #  services.synergy.package
  #  services.telegraf.enable

  #  system.defaults.".GlobalPreferences"."com.apple.sound.beep.sound"
  #  system.defaults.ActivityMonitor.SortColumn

  # !!!
  #  system.defaults.CustomSystemPreferences
  #  system.defaults.CustomUserPreferences
  #  system.defaults.NSGlobalDomain.

  system.primaryUser = "fedorivn";

  system.defaults = {
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
      # Options: "SCev" = Search This Mac, "SCcf" = Search Current Folder, "SCsp" = Use Previous Search Scope
      FXDefaultSearchScope = "SCcf"; # Search current folder by default
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
      # TODO: try this setting
      # AppleSpacesSwitchOnActivate = false;
      InitialKeyRepeat = 12;
      KeyRepeat = 2;

      # NSAutomaticCapitalizationEnabled = true;
      # NSAutomaticDashSubstitutionEnabled = true;
      # NSAutomaticInlinePredictionEnabled = true;
      # NSAutomaticPeriodSubstitutionEnabled = true;
      # NSAutomaticQuoteSubstitutionEnabled = true;
      # NSAutomaticSpellingCorrectionEnabled = true;

      NSDocumentSaveNewDocumentsToCloud = false;
      # Whether to enable moving window by holding anywhere on it like on Linux. The default is false.
      # NSWindowShouldDragOnGesture = true;
      "com.apple.keyboard.fnState" = true;

      # system.defaults.NSGlobalDomain."com.apple.sound.beep.volume"

      # TODO: what is that?
      #  system.defaults.WindowManager.AppWindowGroupingBehavior

      # system.defaults.dock.autohide-delay
      # system.defaults.dock.autohide
      # system.defaults.dock.autohide-time-modifier
      # system.defaults.dock.expose-animation-duration
      # system.defaults.dock.expose-group-by-app
      # system.defaults.dock.mineffect
      # system.defaults.dock.minimize-to-application = true;
      # system.defaults.dock.persistent-apps
      # system.defaults.dock.show-recents
      # system.defaults.dock.tilesize = 64
      # system.defaults.dock.wvous-br-corner = 1;
      # system.defaults.finder.ShowPathbar = true;
      # system.defaults.finder._FXShowPosixPathInTitle = true;
      # system.defaults.screensaver.askForPassword = true;
      # system.defaults.spaces.spans-displays = true;
      # system.keyboard.enableKeyMapping
    };

    #  time.timeZone
    #  users.users
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  networking = {
    hostName = hostname;
    computerName = hostname;
    knownNetworkServices = [
      "USB Controls 2"
      "USB Controls"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ]
    ++ secrets.knownNetworkServices;
    dns = [
      "8.8.8.8"
      "8.8.4.4"
      "1.1.1.1"
      "1.0.0.1"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
  };

  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  services.tailscale.enable = true;

  # https://github.com/LnL7/nix-darwin/issues/786
  # system.activationScripts.extraActivation.text = ''
  #   softwareupdate --install-rosetta --agree-to-license
  # '';
}
