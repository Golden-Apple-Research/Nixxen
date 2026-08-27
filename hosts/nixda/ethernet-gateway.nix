{ config, lib, pkgs, ... }:

{
  # --- USB-Networking für postmarketOS-Geräte (172.16.42.x) ---
  systemd.network.networks."20-pmos-usb" = {
    matchConfig.Name = "en*u* usb*";
    address = [ "172.16.42.2/24" ];
    networkConfig = {
      DHCP = "no";
      ConfigureWithoutCarrier = "yes";
      LinkLocalAddressing = "no";
    };
    linkConfig.RequiredForOnline = "no";
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nat = {
    enable = true;
    internalIPs = [ "172.16.42.0/24" ];
    externalInterface = "eno1";   # z.B. "eno1"
  };

  networking.firewall.trustedInterfaces = [ "enp0s20f0u9" ];   # z.B. "enp0s21u1u3"
}
