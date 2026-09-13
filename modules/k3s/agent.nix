# k3s Agent (Worker) – läuft auf rpi4-4g, rpi4-8g und xiaomi-begonia
{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.k3s = {
    enable = true;
    role = "agent";

    # Control Plane ist nixda – Auflösung muss funktionieren (DNS, mDNS oder
    # statischer Eintrag). Notfalls hier die IP eintragen:
    # TODO: feste IP für nixda festlegen
    serverAddr = lib.mkDefault "https://nixda.home.arpa:6443";

    # Token vom Server holen und auf den Worker kopieren:
    #   sudo cat /var/lib/rancher/k3s/server/node-token   # auf nixda
    # TODO: per sops-nix als Secret ausrollen (siehe README)
    tokenFile = lib.mkDefault "/var/lib/secrets/k3s/token";

    # Bei WireGuard-Overlay (modules/vpn/wireguard.nix): Pod-Netzwerk durch
    # den Tunnel legen statt über das physische Netz
    extraFlags = lib.mkDefault "--flannel-iface=wg0";
  };

  networking.firewall = {
    allowedTCPPorts = [
      10250 # Kubelet
    ];
    allowedUDPPorts = [
      8472 # Flannel VXLAN
      51820 # wg
      51821 # wg
    ];
  };
}
