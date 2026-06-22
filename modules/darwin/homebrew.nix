{ ... }:
{
  homebrew = {
    enable = true;
    greedyCasks = true;
    casks = [
      "telegram"
      "beekeeper-studio"
      "ungoogled-chromium"
      # "libreoffice"
      "keyboardcleantool"
      "lm-studio"
      "obs"
      "mac-mouse-fix"
      "ghostty"
      "handy"
      "swiftbar"
      "raycast"
    ];
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
