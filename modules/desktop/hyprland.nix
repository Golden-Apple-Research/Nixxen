# Hyprland Desktop (tsathoggua)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Wayland für Electron-/Chromium-Apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Audio: PipeWire als PulseAudio-Ersatz
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    brightnessctl
    fuzzel
    hyprpaper
    networkmanagerapplet
    swayidle
    swaylock
    waybar
  ];
}
