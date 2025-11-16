{ config, pkgs, ... }:
{
  # KDE Plasma + SDDM setup
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;

  # Use PipeWire instead of (now legacy) PulseAudio module
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
