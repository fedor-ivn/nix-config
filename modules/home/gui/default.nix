# Desktop-only home configuration.
#
# Everything in this directory is gated on `me.gui.enable`, so headless hosts
# (e.g. fedorivns-homelab) get the shared CLI environment without pulling in
# browsers, editors or a mail client. Desktop hosts opt in from their own
# config — see configurations/{nixos,darwin}/<host>/default.nix.
{ lib, ... }:
{
  options.me.gui.enable = lib.mkEnableOption ''
    GUI applications and desktop-only home config. Off by default so a new
    headless host stays lean without having to opt out of anything
  '';

  # Same auto-import as the parent directory: every sibling module here
  # self-gates on `me.gui.enable`.
  imports =
    with builtins;
    map
      (fn: ./${fn})
      (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
