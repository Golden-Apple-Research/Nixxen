# Kernel-Derivation für Xiaomi Redmi Note 8 Pro ("begonia", MediaTek MT6785)
#
# Quelle: postmarketOS pmaports, Package `linux-postmarketos-mediatek-mt6785`
#   https://gitlab.postmarketos.org/postmarketOS/pmaports/-/tree/master/device/testing/linux-postmarketos-mediatek-mt6785
# Upstream: Mainline-Kernel-Fork https://gitlab.postmarketos.org/mt6785-mainline/linux
#
# Läuft auf x86_64 als CROSS-Build (nixda):
#   nix build .#packages.x86_64-linux.xiaomi-begonia-kernel
# und nativ im aarch64-Host (xiaomi-begonia).
{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  ...
}:

let
  version = "6.16.4";
  # Tag aus dem pmOS-APKBUILD ($_tag = "$pkgver-r0")
  rev = "6.16.4-r0";
in
buildPackages.linuxManualConfig {
  inherit stdenv lib;
  inherit version;

  modDirVersion = version;

  src = fetchurl {
    url = "https://gitlab.postmarketos.org/mt6785-mainline/linux/-/archive/${rev}/linux-${rev}.tar.gz";
    # TODO: Beim ersten Build den korrekten Hash einsetzen:
    #   nix build .#packages.x86_64-linux.xiaomi-begonia-kernel
    #   → Fehlermeldung enthält den erwarteten Hash (sha256-...)
    hash = lib.fakeHash;
  };

  # Laufende, bekannte-gute Config vom Gerät selbst (von /proc/config.gz des
  # installierten pmOS kopiert). Original aus pmaports: config-mt6785.aarch64
  configfile = ./kconfig.aarch64;

  # Erlaubt das Lesen der Config aus dem Store (nötig für linuxManualConfig)
  allowImportFromDerivation = true;
}
