# Kernel-Modul für den Xiaomi-Host (begonia)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Der MT6785-Mainline-Fork aus dem pmOS-Umfeld statt des generischen
  # NixOS-aarch64-Kernels.
  #
  # HINWEIS: Config-Eingriffe (z. B. CONFIG_CMDLINE, fehlende Treiber= y/m)
  # am besten upstream in der eingecheckten config-mt6785.aarch64 ändern:
  #   modules/hardware/xiaomi-begonia/config-mt6785.aarch64
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./kernel-pkg.nix { });

  # Initrd-Module aus dem pmOS modules-initfs (Display/Backlight/Touch,
  # damit früh eine Konsole da ist):
  boot.initrd.kernelModules = [
    "lm36274_bl"
    "lm363x-regulator"
    "novatek-nvt-ts-spi"
    "panel-novatek-nt36672a"
    "ti-lmu"
  ];
}
