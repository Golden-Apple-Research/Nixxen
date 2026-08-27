# Main Server nixda
# Headless, Intel 4 Core / 32 GB RAM – Build-Server, k3s-Server, Spielwiese
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common
    ./hardware-configuration.nix
    ./ethernet-gateway.nix
    ../../modules/k3s/server.nix
    ../../modules/vpn/wireguard.nix
  ];

  networking.hostName = "nixda";

  # Bootloader – stand vorher in der alten configuration.nix
  # (nixos-generate-config legt die nicht in die hardware-configuration.nix)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ethernet-gateway.nix nutzt systemd-networkd (.network-Dateien greifen
  # nur mit aktiviertem networkd). Achtung bei Remote-Wechsel:
  # erst prüfen, dass DHCP auf eno1 über networkd weiter funktioniert!
  networking.useNetworkd = true;

  # WireGuard-Hub für den k3s-Cluster (Client-Peers unten eintragen)
  services.nixxen.wireguard = {
    enable = true;
    role = "server";
    address = "10.42.7.1/24";
    peers = [
      # { publicKey = "…"; allowedIPs = [ "10.42.7.2/32" ]; }  # rpi4-4g
      # { publicKey = "…"; allowedIPs = [ "10.42.7.3/32" ]; }  # rpi4-8g
      # { publicKey = "…"; allowedIPs = [ "10.42.7.4/32" ]; }  # xiaomi-begonia
    ];
  };

  # Build-Server: erlaubt transparente Emulation für aarch64-Hosts
  # (Raspberry Pis, Xiaomi) – echte Cross-Compiles via remote Builder sind
  # schneller, siehe README.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Remote-Builder: erlaubt Build-Jobs von anderen Maschinen, z. B.
  #   nixos-rebuild switch --flake .#xiaomi-begonia \
  #     --target-host root@begonia --build-host mal-2@nixda
  # (oder per builders = "ssh://mal-2@nixda aarch64-linux" im nix.conf des Clients)
  nix.settings.trusted-users = [ "mal-2" ];

  # Xiaomi ist per USB-Tethering (Ethernet over USB) angeschlossen:
  # Auf dem Handy "USB-Tethering" aktivieren → Interface usb0.
  # Standardmäßig holt sich jeder Interface per DHCP eine Adresse.
  # Für einen stabilen k3s-Betrieb besser statisch, z. B.:
  # networking.interfaces.usb0.ipv4.addresses = [{
  #   address = "192.168.42.2";
  #   prefixLength = 24;
  # }];
}
