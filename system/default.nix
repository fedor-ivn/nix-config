{
  self,
  system,
  pkgs,
  username,
  hostname,
  ...
}:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # darwin.xcode
    htop
    neovim
    neofetch
  ];

  users.users.fedorivn = {
    name = "fedorivn";
    home = "/Users/fedorivn";
  };

  security.pam.enableSudoTouchIdAuth = true;
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
  #  services.skhd.enable 
  #  services.spacebar.enable 
  #  services.spotifyd.enable 
  #  services.synapse-bt.enable 
  #  services.synergy.package 
  #  services.telegraf.enable 
  #  services.yabai.enable 

  #  system.defaults.".GlobalPreferences"."com.apple.sound.beep.sound" 
  #  system.defaults.ActivityMonitor.SortColumn

  # !!! 
  #  system.defaults.CustomSystemPreferences 
  #  system.defaults.CustomUserPreferences 
  #  system.defaults.NSGlobalDomain.

  system.defaults = {
    finder.CreateDesktop = false;
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
      # InitialKeyRepeat = 1;
      # KeyRepeat = 1;

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

  services.nix-daemon.enable = true;
  nix = {
    gc.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };

  networking = {
    hostName = hostname;
    computerName = hostname;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
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
  system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
