{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".config/raycast/scripts/switch-input-source-to-english.sh" = {
    executable = true;
    text = ''
      #!/bin/bash

      # Required parameters:
      # @raycast.schemaVersion 1
      # @raycast.title Switch to English
      # @raycast.mode silent
      # @raycast.packageName Input Source

      ${pkgs.macism}/bin/macism com.apple.keylayout.ABC
    '';
  };

  home.file.".config/raycast/scripts/switch-input-source-to-russian.sh" = {
    executable = true;
    text = ''
      #!/bin/bash

      # Required parameters:
      # @raycast.schemaVersion 1
      # @raycast.title Switch to Russian
      # @raycast.mode silent
      # @raycast.packageName Input Source

      ${pkgs.macism}/bin/macism com.apple.keylayout.RussianWin
    '';
  };

  home.file.".config/raycast/scripts/mic-toggle.sh" = {
    executable = true;
    text = ''
      #!/bin/bash

      # Required parameters:
      # @raycast.schemaVersion 1
      # @raycast.title Toggle Microphone
      # @raycast.mode silent

      current=$(osascript -e "input volume of (get volume settings)")
      if [ "$current" -eq 0 ]; then
          osascript -e "set volume input volume 30"
      else
          osascript -e "set volume input volume 0"
      fi
    '';
  };

  home.file.".config/swiftbar/plugins/volume.250ms.sh" = {
    executable = true;
    text = ''
      #!/bin/bash

      vol=$(osascript -e "input volume of (get volume settings)")

      if [ "$vol" -eq 0 ]; then
          echo ":mic.slash.fill: | sfcolor=systemRed symbolize=true"
      else
          echo ":mic.fill: | sfcolor=systemGreen symbolize=true"
      fi
    '';
  };
}
