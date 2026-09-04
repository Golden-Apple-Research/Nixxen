# WireGuard-Overlay für den k3s-Cluster
#
# nixda ist der Hub (10.42.7.1), alle Worker verbinden sich von sich aus raus
# (funktioniert damit auch hinter NAT, PersistentKeepalive hält die Verbindung).
# k3s läuft dann komplett über wg0 (siehe --flannel-iface in den k3s-Modulen).
#
# Der Private Key wird pro Host einmalig erzeugt und liegt persistent unter
# /etc/wireguard/wg0.key (Service "wireguard-key", vor networkd).
# PubKey für die Gegenseite auslesen:
#   sudo cat /etc/wireguard/wg0.key | wg pubkey
# Später sauberer: per sops-nix ausrollen.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.nixxen.wireguard;
in
{
  options.services.nixxen.wireguard = {
    enable = lib.mkEnableOption "WireGuard-Overlay für k3s";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      description = "server = Hub auf nixda, client = Worker.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      description = "Eigene Adresse im Overlay, z. B. 10.42.7.1/24.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
    };

    # --- server ---
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ "worker-1" ];
      description = ''
        Worker-Peers: [{ publicKey, allowedIPs }].
      '';
      worker-1 = [
        {
          publicKey = "RPuqsBfb5XWIWlNZhIW88+oB/u0Jdn5a1X95XgcnA38=";
          allowedIPs = [ "10.42.7.2/32" ];
        }
      ];
    };

    # --- client ---
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "nixda.home.arpa:51820";
    };

    serverPublicKey = lib.mkOption {
      type = lib.types.str;
      default = "1WNZ3ny64CRPKEoXmoxM9Y2M7d83KzeCPf9HkrHMAyw=";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces.wg0 = {
      inherit (cfg) listenPort;
      ips = [ cfg.address ];

      # Mit networkd muss der Key als Datei vorliegen (generatePrivateKeyFile
      # geht dort nicht). Erzeugung beim ersten Aktivieren, danach persistent:
      privateKeyFile = "/etc/wireguard/wg0.key";

      peers =
        if cfg.role == "server" then
          cfg.peers
        else
          [
            {
              publicKey = cfg.serverPublicKey;
              allowedIPs = [ "10.42.7.0/24" ];
              endpoint = cfg.endpoint;
              # Handy/Pi hinter NAT: hält den Tunnel offen
              persistentKeepalive = 25;
            }
          ];
    };

    # Key einmalig erzeugen (persistent), falls noch nicht vorhanden.
    # PubKey danach auslesen:
    #   sudo cat /etc/wireguard/wg0.key | wg pubkey
    systemd.services.wireguard-key = {
      description = "WireGuard Private Key für wg0";
      wantedBy = [ "multi-user.target" ];
      before = [ "systemd-networkd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -s /etc/wireguard/wg0.key ]; then
          mkdir -p /etc/wireguard
          chmod 700 /etc/wireguard
          ${pkgs.wireguard-tools}/bin/wg genkey > /etc/wireguard/wg0.key
          chmod 600 /etc/wireguard/wg0.key
          echo "wireguard: neuen Private Key für wg0 erzeugt"
        fi
      '';
    };

    networking.firewall = {
      # Server: WG-Port von außen erreichbar machen
      allowedUDPPorts = lib.mkIf (cfg.role == "server") [ cfg.listenPort ];
      # Overlay-Verkehr ist vertrauenswürdig (VXLAN läuft getunnelt über wg0)
      trustedInterfaces = [ "wg0" ];
    };
  };
}
