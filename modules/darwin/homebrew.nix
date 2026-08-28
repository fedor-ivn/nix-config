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
      "ungoogled-chromium"
      "keyboardcleantool"
      "mac-mouse-fix"
      "ghostty"
      "swiftbar"
      "raycast"
    ] ++ secrets.homebrewCasks;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
      # Skip "Do you want to proceed with the cleanup?" prompt during zap.
      extraFlags = [ "--force" ];
    };
  };
}
