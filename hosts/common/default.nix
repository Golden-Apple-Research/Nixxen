# Gemeinsame Basis für alle Hosts
#
# Wird von jedem Host unter hosts/ importiert.
{
  config,
  lib,
  pkgs,
  sops-nix,
  ...
}:

{
  imports = [
    # sops-nix ist importiert und einsatzbereit – Secrets werden aber erst
    # aktiv, sobald `sops.*` konfiguriert ist (siehe README).
    sops-nix.nixosModules.sops
  ];

  nixpkgs.config.allowUnfree = true; # z. B. für Firmware-Pakete

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # RFC 8375 Home Network Domain – funktioniert nur, wenn euer Router/FW-DNS
  # `nixda.home.arpa` & Co. auflöst, sonst Hosts unten per extraHosts/IP anpassen.
  networking.domain = "home.arpa";

  networking.timeServers = [ "pool.ntp.org" ];

  time.timeZone = "Europe/Berlin";
  # Ich nutze ein us layout, NICHT UMSTELLEN!!!
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # mDNS (.local-Namen im LAN), hilfreich für die k3s-Nodes
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  environment.systemPackages = with pkgs; [
    btop
    curl
    git
    htop
    ripgrep
    vim
    wget
  ];

  users.users.nx = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # TODO: Nach dem ersten Login ändern oder (besser) durch
    #   hashedPasswordFile (sops-nix) ersetzen:
    initialPassword = "changeme";
    # TODO: Vor dem ersten headless Deploy einen echten Key hinterlegen,
    # SSH-Login ist nur per Key erlaubt!
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3Nza... nx@tsathoggua"
    ];
  };

  system.stateVersion = "25.05";
}
