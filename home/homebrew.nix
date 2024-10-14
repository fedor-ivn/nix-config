{
  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew
    enable = true;

    casks = [
      "firefox"
      "vlc"
      "telegram"
      "altserver"
      "beekeeper-studio"
    ];

    global.autoUpdate = false;
    onActivation = {
      cleanup = "zap";
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
