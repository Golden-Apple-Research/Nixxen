# NAT64 + DNS64 für den Single-Stack-IPv6-Cluster
#
# Warum: ein IPv6-only-Cluster erreicht IPv4-only-Ziele nicht. Gemessen sind das
# u. a. ghcr.io (Images), github.com (Flux-GitRepository) und der
# Supabase-Session-Pooler (Keycloak/Windmill-DB) — ohne Übersetzung ist der
# Cluster nicht bootstrappbar. Details: k3s/PLAN-cilium-ipv6.md
#
# Aufbau:
#   Pod → CoreDNS → (forward .) → unbound (DNS64) → Mikrotik
#   Pod → 2a02:21b4:8c69:63ff::<v4> → jool (NAT64) → IPv4-Ziel
#
# unbound läuft auf dem Host und hat selbst IPv4 — es fragt die Authoritativen
# direkt über v4 und liefert den Pods synthetische AAAA-Records.
{
  lib,
  ...
}:

let
  # Netzplan aus dem ISP-/56 2a02:21b4:8c69:6300::/56
  lanCIDR = "2a02:21b4:8c69:6300::/64";
  podCIDR = "2a02:21b4:8c69:6304::/62";
  nat64Prefix = "2a02:21b4:8c69:63ff::/96";
  nodeIPv6 = "2a02:21b4:8c69:6300:9ae7:f4ff:febd:b6a2";
  upstreamDNS = "2a02:21b4:8c69:6300::1"; # Mikrotik
in
{
  # --- NAT64: IPv6-Pool, aus dem IPv4-Ziele erreichbar sind (RFC 6052) ---
  services.jool.nat64.default = {
    framework = "netfilter";
    global.pool6 = nat64Prefix;
  };

  # --- DNS64: liefert Pods AAAA-Records für IPv4-only-Namen ---
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "::1"
          nodeIPv6
        ];
        access-control = [
          "0.0.0.0/0 refuse"
          "::/0 refuse"
          "::1/128 allow"
          "${podCIDR} allow"
          "${lanCIDR} allow"
        ];
        # unbound erwartet die Modulliste in Anführungszeichen, der
        # NixOS-Generator schreibt Strings unverändert → Quotes mitgeben.
        "module-config" = "\"dns64 iterator\"";
        "dns64-prefix" = nat64Prefix;
        "do-not-query-localhost" = false;
        "cache-max-ttl" = 3600;
        # Kein IPv6-AAAA für ULA-lose Ziele raten — DNS64 synthetisiert nur,
        # wenn wirklich kein AAAA existiert.
        "dns64-synthall" = false;
      };
      "forward-zone" = [
        {
          name = ".";
          "forward-addr" = upstreamDNS;
        }
      ];
    };
  };

  # jool braucht IPv6-Forwarding; Cilium setzt das ebenfalls, hier explizit.
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
}
