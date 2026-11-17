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
      # HA-Setup mit eingebettetem etcd, falls später weitere Server dazukommen:
      "--cluster-init"

      # --- CNI & Proxy: Cilium übernimmt beides (k3s/PLAN-cilium-ipv6.md) ---
      "--flannel-backend=none"
      "--disable-network-policy" # sonst blockiert k3s die NetworkPolicy-CRDs
      "--disable-kube-proxy" # eBPF kube-proxy-replacement
      "--disable=traefik" # ersetzt durch Cilium Gateway API
      "--disable=servicelb" # Cilium LB-IPAM + NetBird

      # --- Single-Stack IPv6 aus dem ISP-/56 2a02:21b4:8c69:6300::/56 ---
      "--cluster-cidr=2a02:21b4:8c69:6304::/62" # 4× /64 für Nodes
      "--service-cidr=2a02:21b4:8c69:6308::/112"
      "--cluster-dns=2a02:21b4:8c69:6308::a"
      "--node-cidr-mask-size-ipv6=64"
      # kubelet nimmt sonst IPv4 als primäre Familie
      "--node-ip=2a02:21b4:8c69:6300:9ae7:f4ff:febd:b6a2"
      "--kubelet-arg=node-ip=2a02:21b4:8c69:6300:9ae7:f4ff:febd:b6a2"

      "--tls-san=nixda.home.arpa"
      "--tls-san=2a02:21b4:8c69:6300:9ae7:f4ff:febd:b6a2"
    ];

    # Node-Token für die Agenten auslesen (auf nixda):
    #   sudo cat /var/lib/rancher/k3s/server/node-token
    # TODO: Token per sops-nix auf alle Worker ausrollen (siehe README)
  };

  # kubectl etc. (`k3s kubectl ...`) + Cilium-CLI für die Erstinstallation
  # (`cilium install`) und Diagnose (`cilium status`, `cilium connectivity test`)
  environment.systemPackages = [
    config.services.k3s.package
    pkgs.cilium-cli
  ];

  # Default-Route kommt per RA vom Mikrotik — ohne accept_ra=2 verwirft der
  # Node die Route, sobald sie abläuft (k3s-Known-Issue, Single-Stack IPv6).
  boot.kernel.sysctl."net.ipv6.conf.all.accept_ra" = 2;

  networking.firewall = {
    allowedTCPPorts = [
      6443 # Kubernetes API
      10250 # Kubelet
      2379 # etcd
      2380 # etcd
      80 # http (Gateway)
      443 # https (Gateway)
      4240 # Cilium health
    ];
    allowedUDPPorts = [
      51820 # wg
      51821 # wg
    ];
    # 8472/udp (Flannel VXLAN) entfällt: Cilium läuft mit routingMode=native.
    #
    # Achtung: die nftables-Firewall hat in der forward-chain policy drop.
    # Pod-Traffic (Cilium-veths `lxc*`) und NetBird-Zustellungen müssen daher
    # explizit erlaubt werden, sonst kommt weder Egress noch der Rückweg an.
    extraForwardRules = ''
      iifname "lxc*" accept
      oifname "lxc*" accept
      iifname "wt0" accept
    '';
  };
}
