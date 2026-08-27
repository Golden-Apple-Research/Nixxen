# k3s-Worker: Raspberry Pi 4, 4 GB RAM
{
  config,
  lib,
  pkgs,
  nixos-hardware,
  nixpkgs,
  ...
}:

{
  imports = [
    ../common
    ../../modules/hardware/rpi4.nix
    ../../modules/k3s/agent.nix
    ../../modules/vpn/wireguard.nix

    # SD-Karten-Image bauen (siehe README) – dafür diesen Import aktivieren:
    # (nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
  ];

  networking.hostName = "rpi4-4g";

  # Overlay-Verbindung zu nixda (Hub) – PubKey von nixda eintragen
  # services.nixxen.wireguard = {
  #   enable = true;
  #   role = "client";
  #   address = "10.42.7.2/24";
  #   serverPublicKey = "…";
  # };
}
