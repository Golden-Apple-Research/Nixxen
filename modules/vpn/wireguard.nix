# WireGuard-Overlay für den k3s-Cluster
#
# nixda ist der Hub (10.42.7.1), alle Worker verbinden sich von sich aus raus
# (funktioniert damit auch hinter NAT, PersistentKeepalive hält die Verbindung).
# k3s läuft dann komplett über wg0 (siehe --flannel-iface in den k3s-Modulen).
#
# Keys erzeugen:
#   nix-shell -p wireguard-tools --run 'wg genkey | tee privatekey | wg pubkey'
# Private Keys gehören idealerweise in sops-nix; für den Skeleton als
# Platzhalter per File unter /var/lib/secrets/wireguard/.
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
      default = [ ];
      description = ''
        Worker-Peers: [{ publicKey, allowedIPs }].
      '';
      example = [
        {
          publicKey = "wGh7…=";
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
      default = "TODO-PUBKEY-NIXDA";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces.wg0 = {
      inherit (cfg) listenPort;
      ips = [ cfg.address ];

      # TODO: privaten Key per sops-nix ausrollen, z. B.:
      #   privateKeyFile = "/run/secrets/wireguard_private";
      generatePrivateKeyFile = true;

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

    networking.firewall = {
      # Server: WG-Port von außen erreichbar machen
      allowedUDPPorts = lib.mkIf (cfg.role == "server") [ cfg.listenPort ];
      # Overlay-Verkehr ist vertrauenswürdig (VXLAN läuft getunnelt über wg0)
      trustedInterfaces = [ "wg0" ];
    };
  };
}
