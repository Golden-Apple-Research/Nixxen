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
      # Root nur per Key (Notfall-Zugang, users.users.root weiter unten)
      PermitRootLogin = "prohibit-password";
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

  users.users.root = {
    hashedPassword = "$6$KZBEAY3J2lXDbC7z$RTuMDY/h3Z0MdTv9In3ROjLA3VNGHU466CeiQ1VRCw8yG/QMNF49ePcR0mQacjhGdccKqyXHGI4kNQaBxwui91";
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE0eEEBd//xMxb9O3662lYYnKN2o8Q4BJh0NSbMVoSfIAAAACHNzaDpyb290 root@tsathoggua"
    ];
  };
  users.users.mal-2 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # TODO: Nach dem ersten Login ändern oder (besser) durch
    #   hashedPasswordFile (sops-nix) ersetzen:
    hashedPassword = "$6$oWKuDcrn.LTNURux$y2gw3lxUBdpzgZ2/8qZM3eSCFRBglB.aV3vcFs5QZWc3oV89Tr1fvq5L2z5wXMSDLPfIxVsl6DZ4RYZWrVqn.1";
    # TODO: Vor dem ersten headless Deploy einen echten Key hinterlegen,
    # SSH-Login ist nur per Key erlaubt!
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDzz6cca0kfmFeCToPefLxVabxkMNVia9yPeutsoZyuKAAAACXNzaDptYWwtMg== mal-2@tsathoggua"
    ];
  };

  system.stateVersion = "25.05";
}
