{
  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew
    enable = true;

    brews =
        [
          {name = "laishulu/homebrew/macism";}
        ];

    casks =
      map
        (name: {
          name = name;
          greedy = true;
        })
        [
          "firefox"
          "thunderbird"
          "vlc"
          "telegram"
          "altserver"
          "beekeeper-studio"
          "google-chrome"
          "libreoffice"
          "keyboardcleantool"
          "logi-options+"
          "chatgpt"
          "lm-studio"
        ]
      ++ [
        # Touch ID unlock support on macOS isn't working for nixpkgs build of
        # KeePassXC, so the Homebrew version is used instead.
        # TODO: Track this issue - https://github.com/NixOS/nixpkgs/issues/241103
        "keepassxc"
      ];

    caskArgs.no_quarantine = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # masApps = {
    #     "wireguard" = 1451685025;
    # };
  };
}
