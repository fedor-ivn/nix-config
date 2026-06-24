{ flake, ... }:
let
  secrets = flake.inputs.secrets.values;
in
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
      "mac-mouse-fix"
      "ghostty"
      "handy"
      "swiftbar"
      "raycast"
    ] ++ secrets.homebrewCasks;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
