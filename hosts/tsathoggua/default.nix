# Main Desktop tsathoggua
# Lenovo ThinkPad, AMD Ryzen 7 5700U / 16 GB RAM, Dockingstation, Hyprland
{
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:

{
  imports = [
    ../common
    ./hardware-configuration.nix
    ../../modules/desktop/hyprland.nix

    # Home Manager für den Desktop-User
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.mal-2 = import ./home.nix;
    }
  ];

  networking.hostName = "tsathoggua";

  # AMD Renoir iGPU (amdgpu ist im Kernel aktiv, Mesa als Standard)
  hardware.graphics.enable = true;

  # Dockingstation: External Displays per USB-C/DP sollten out-of-the-box gehen
  boot.initrd.availableKernelModules = [
    "nvme"
    "usbhid"
    "usb_storage"
  ];
}
