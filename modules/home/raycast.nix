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
}
