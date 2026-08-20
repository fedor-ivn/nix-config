{ config, lib, ... }:
lib.mkIf config.me.gui.enable {
  programs.obsidian = {
    enable = true;
    cli.enable = true;
  };
}
