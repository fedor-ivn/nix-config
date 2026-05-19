{ flake, ... }:
let
  secrets = flake.inputs.secrets.values;
in
{
  homebrew = {
    enable = true;
    casks = map
      (name: {
        inherit name;
        greedy = true;
      })
      ([
        "telegram"
        "altserver"
        "beekeeper-studio"
        "ungoogled-chromium"
        # "libreoffice"
        "keyboardcleantool"
        "lm-studio"
        "obs"
        "mac-mouse-fix"
        "chatgpt"
        "claude"
        "ghostty"
        "handy"
        "swiftbar"
      ] ++ secrets.homebrewCasks);
    # caskArgs.no_quarantine = true; # Deprecated flag, removed by Homebrew
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
