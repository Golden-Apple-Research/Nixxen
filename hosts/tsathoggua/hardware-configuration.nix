# PLATZHALTER – nach der Installation durch die echte Konfig ersetzen:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > hosts/tsathoggua/hardware-configuration.nix
#
{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
