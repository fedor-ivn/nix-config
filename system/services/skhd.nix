{
  lib,
  pkgs,
  brewPrefix,
  ...
}:

let
  modifier = "alt";
  mkSpaceShortcut =
    num: "shift + ${modifier} - ${toString num} : yabai -m window --space ${toString num};\n";
  spaceShortcuts = lib.strings.concatStrings (map mkSpaceShortcut (lib.lists.range 1 9));
  toggleLayoutScript = pkgs.writeShellScriptBin "toggle-layout" ''
    #!/usr/bin/env bash

    # Get the current space
    CURRENT_SPACE=$(yabai -m query --spaces --space | jq '.index')
    
    # Get the current layout of the space
    CURRENT_LAYOUT=$(yabai -m query --spaces --space | jq -r '.type')
    
    # Determine the next layout
    # Toggle the layout
    if [ "$CURRENT_LAYOUT" = "bsp" ]; then
      NEW_LAYOUT="stack"
    else
      NEW_LAYOUT="bsp"
    fi
    
    # Apply the new layout to current space
    yabai -m space --layout "$NEW_LAYOUT"
  '';
in
''
  # Having troubles finding hotkey? Just type `skhd --observe` in a terminal and
  # type a key. Pretty cool! Or just check the wiki.


  # -- Changing Window Focus --

  # change window focus within space
  ${modifier} - j : yabai -m window --focus south
  ${modifier} - k : yabai -m window --focus north
  ${modifier} - h : yabai -m window --focus west
  ${modifier} - l : yabai -m window --focus east

  # change focus between external displays (left and right)
  # ${modifier} - d : yabai -m display --focus south
  # ${modifier} - f : yabai -m display --focus north
  # ${modifier} - s : yabai -m display --focus west
  # ${modifier} - g : yabai -m display --focus east

  # Since shift + alt + f conflicts with formatter in VSCode and I have my
  # laptop placed right below the external monitor, I only need two keys to 
  # control them.
  ${modifier} - s : yabai -m display --focus south
  ${modifier} - d : yabai -m display --focus north

  # -- Modifying the Layout --

  # rotate layout clockwise
  shift + ${modifier} - r : yabai -m space --rotate 270

  # flip along y-axis
  shift + ${modifier} - y : yabai -m space --mirror y-axis

  # flip along x-axis
  shift + ${modifier} - x : yabai -m space --mirror x-axis

  # toggle window float
  shift + ${modifier} - t : yabai -m window --toggle float --grid 8:8:1:1:6:6

  # toggle bsp/stack space layout

  shift + ${modifier} - space : ${toggleLayoutScript}/bin/toggle-layout

  # -- Modifying Window Size --

  # maximize a window
  shift + ${modifier} - m : yabai -m window --toggle zoom-fullscreen

  # balance out tree of windows (resize to occupy same area)
  ${modifier} - e : yabai -m space --balance

  # -- Moving Windows Around --

  # swap windows
  shift + ${modifier} - h : yabai -m window --swap west
  shift + ${modifier} - j : yabai -m window --swap south
  shift + ${modifier} - k : yabai -m window --swap north
  shift + ${modifier} - l : yabai -m window --swap east

  # move window and split
  ctrl + ${modifier} - h : yabai -m window --warp west
  ctrl + ${modifier} - j : yabai -m window --warp south
  ctrl + ${modifier} - k : yabai -m window --warp north
  ctrl + ${modifier} - l : yabai -m window --warp east

  # move window to display
  # shift + ${modifier} - d : yabai -m window --display south; yabai -m display --focus south;
  # shift + ${modifier} - f : yabai -m window --display north; yabai -m display --focus north;
  # shift + ${modifier} - s : yabai -m window --display west; yabai -m display --focus west;
  # shift + ${modifier} - g : yabai -m window --display east; yabai -m display --focus east;

  # Since shift + alt + f conflicts with formatter in VSCode and I have my
  # laptop placed right below the external monitor, I only need two keys to 
  # control them.
  shift + ${modifier} - s : yabai -m window --display south; yabai -m display --focus south;
  shift + ${modifier} - d : yabai -m window --display north; yabai -m display --focus north;

  # move window to prev and next space
  shift + ${modifier} - p : yabai -m window --space prev;
  shift + ${modifier} - n : yabai -m window --space next;

  # move window to space #
  ${spaceShortcuts}

  # -- Starting/Stopping/Restarting Yabai --

  # stop/start/restart yabai
  ctrl + ${modifier} - q : yabai --stop-service;
  ctrl + ${modifier} - s : yabai --start-service;
  ctrl + ${modifier} - r : yabai --restart-service;

  # -- Change the input source --
  ${modifier} - 1 : ${brewPrefix}/macism com.apple.keylayout.ABC;
  ${modifier} - 2 : ${brewPrefix}/macism com.apple.keylayout.RussianWin;
''
