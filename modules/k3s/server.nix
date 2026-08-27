# k3s Server (Control Plane) – läuft auf nixda
{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.k3s = {
    enable = true;
    role = "server";

    extraFlags = lib.concatStringsSep " " [
      # kubectl als normaler User nutzbar
      "--write-kubeconfig-mode=0644"
      # Pod-Netzwerk durch das WireGuard-Overlay
      "--flannel-iface=wg0"
      # HA-Setup mit eingebettetem etcd, falls später weitere Server dazukommen:
      # "--cluster-init"
      # Eigenen Ingress statt Traefik, falls gewünscht:
      # "--disable=traefik"
    ];

    # Node-Token für die Agenten auslesen (auf nixda):
    #   sudo cat /var/lib/rancher/k3s/server/node-token
    # TODO: Token per sops-nix auf alle Worker ausrollen (siehe README)
  };

  # kubectl etc. (`k3s kubectl ...`)
  environment.systemPackages = [ config.services.k3s.package ];

  networking.firewall = {
    allowedTCPPorts = [
      6443 # Kubernetes API
      10250 # Kubelet
    ];
    allowedUDPPorts = [
      8472 # Flannel VXLAN
    ];
    # Bei cluster-init zusätzlich: TCP 2379 2380 (etcd)
    # Bei Wireguard-Backend (canal): UDP 51820 51821
  };
}
