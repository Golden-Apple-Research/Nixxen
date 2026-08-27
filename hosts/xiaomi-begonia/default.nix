# Xiaomi Redmi Note 8 Pro ("begonia", MediaTek MT6785)
# k3s-Worker via USB-Tethering (Ethernet over USB) an nixda
#
# Installations-Weg vom laufenden postmarketOS aus (Kernel hat CONFIG_KEXEC=y,
# nixos-anywhere funktioniert daher im Standard-Flow):
#   1. Kernel-Quelle: pmOS-Fork (Mainline 6.16.4), siehe
#      modules/hardware/xiaomi-begonia/kernel-pkg.nix
#   2. Leeres recovery-DTBO vom pmOS kopieren (siehe boot.nix)
#   3. root-Dateisystem auf der userdata-Partition, Install-Schritte
#      stehen in der README
#   4. Boot läuft über unsere boot.img (mkbootimg), kein Standard-Bootloader
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common
    ../../modules/hardware/xiaomi-begonia/kernel.nix
    ../../modules/hardware/xiaomi-begonia/boot.nix
    ../../modules/k3s/agent.nix
    ../../modules/vpn/wireguard.nix
  ];

  networking.hostName = "xiaomi-begonia";

  # Overlay-Verbindung zu nixda – handy-tauglich, da der Client raus wählt
  # (NAT auf nixda egal), PersistentKeepalive hält den Tunnel offen
  # services.nixxen.wireguard = {
  #   enable = true;
  #   role = "client";
  #   address = "10.42.7.4/24";
  #   serverPublicKey = "…";
  # };

  hardware.xiaomiBegonia = {
    # Nach dem ersten erfolgreichen Boot aktivieren:
    # flashBoot = true;
    # bootPartition = "/dev/disk/by-partlabel/boot";
    # recoveryDtbo = ./empty.dtbo;  # einmalig von pmOS kopieren
  };

  # root auf der userdata-Partition (UFS-Speicher):
  # TODO: Partitionierung per disko oder manuell; Label/partlabel anpassen
  # fileSystems."/" = {
  #   device = "/dev/disk/by-partlabel/userdata";
  #   fsType = "ext4";
  # };
}
