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

    # Kein flannel mehr (Cilium, siehe modules/k3s/server.nix).
    #
    # Single-Stack IPv6: jeder Agent braucht seine eigene IPv6 als node-ip,
    # sonst nimmt das kubelet IPv4 als primäre Familie. Pro Host setzen:
    #   services.k3s.extraFlags = lib.mkForce
    #     "--node-ip=2a02:21b4:8c69:6300:<iid>";
    extraFlags = lib.mkDefault "";
  };

  networking.firewall = {
    allowedTCPPorts = [
      10250 # Kubelet
      4240 # Cilium health
    ];
    allowedUDPPorts = [
      51820 # wg
      51821 # wg
    ];
    # 8472/udp (Flannel VXLAN) entfällt — Cilium, routingMode=native.
    # forward-chain hat policy drop: Cilium-veths explizit erlauben.
    extraForwardRules = ''
      iifname "lxc*" accept
      oifname "lxc*" accept
    '';
  };
}
