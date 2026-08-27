# Raspberry Pi 4 – Basis (geteilt von rpi4-4g und rpi4-8g)
# K3s-Worker-Node, siehe modules/k3s/agent.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.enableRedistributableFirmware = true;

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Für k3s/Kubernetes zwingend nötige cgroups
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  # Konvention des sd-image-Installers (Label der SD-Karte)
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Alternativ/ergänzend die gepflegten Module aus nixos-hardware nutzen,
  # z. B. für Device-Tree-Overlays (Kamera, GPIO, ...):
  # imports = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
}
