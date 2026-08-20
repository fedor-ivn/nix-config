{ config, lib, ... }:
lib.mkIf config.me.gui.enable {
  programs.firefox = {
    enable = true;
  };
}
