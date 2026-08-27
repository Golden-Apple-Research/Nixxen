# Android-Boot-Image ("boot.img") statt klassischem Bootloader für begonia
#
# Das Redmi Note 8 Pro hat weder UEFI noch U-Boot: Kernel + initrd + cmdline
# müssen als Android-boot.img in die boot-Partition geschrieben werden
# (header v2, DTB + leeres recovery-DTBO mitgegeben – Parameter aus der
# pmOS deviceinfo von xiaomi-begonia).
#
# Trick: NixOS-Generationen leben ganz normal im /nix/store auf der
# userdata-Partition. Nur wenn sich Kernel/initrd/cmdline ändern, wird eine
# neue boot.img erzeugt und geflasht – reine Config-Änderungen laufen über
# den normalen switch-to-configuration-Mechanismus durch.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.xiaomiBegonia;
in
{
  options.hardware.xiaomiBegonia = {
    bootPartition = lib.mkOption {
      type = lib.types.str;
      description = "Gerätedatei der Android boot-Partition.";
      default = "/dev/disk/by-partlabel/boot";
    };

    flashBoot = lib.mkEnableOption ''
      boot.img bei Kernel-/initrd-Änderungen automatisch in die
      boot-Partition schreiben
    '';

    # pmOS: "begonia bootloader needs empty dtbo"
    recoveryDtbo = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = ''
        Leeres recovery-DTBO (bei pmOS unter /boot/empty.dtbo zu finden).
        Einmalig vom laufenden pmOS kopieren:
          scp root@begonia:/boot/empty.dtbo modules/hardware/xiaomi-begonia/empty.dtbo
      '';
      default = null;
    };
  };

  config = lib.mkMerge [
    {
      # Keine klassischen Bootloader – boot.img kommt von uns
      boot.loader.grub.enable = false;
      boot.loader.systemd-boot.enable = false;
      boot.loader.generic-extlinux-compatible.enable = false;

      system.build.begoniaBootImage =
        with pkgs;
        runCommand "begonia-boot.img"
          {
            nativeBuildInputs = [ mkbootimg ];
          }
          ''
            mkbootimg \
              --kernel "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}" \
              --ramdisk "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}" \
              --dtb "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt6785-xiaomi-begonia.dtb" \
              ${lib.optionalString (cfg.recoveryDtbo != null) ''--recovery_dtbo "${cfg.recoveryDtbo}" \''}
              --cmdline "${lib.concatStringsSep " " (
                [ "bootopt=64S3,32N2,64N2" ] ++ config.boot.kernelParams
              )}" \
              --header_version 2 \
              --base 0x40078000 \
              --kernel_offset 0x00008000 \
              --ramdisk_offset 0x07c08000 \
              --second_offset 0xbff88000 \
              --tags_offset 0x0bc08000 \
              --pagesize 2048 \
              --output "$out"
          '';
    }

    (lib.mkIf cfg.flashBoot {
      system.activationScripts.begoniaBootImage = lib.stringAfter [ "etc" ] ''
        IMG="${config.system.build.begoniaBootImage}"
        SUM=$(sha256sum "$IMG" | cut -d' ' -f1)
        LAST=""
        [ -f /var/lib/xiaomi-begonia-boot.sha256 ] && LAST=$(cat /var/lib/xiaomi-begonia-boot.sha256)
        if [ "$SUM" != "$LAST" ]; then
          echo "begonia: neue boot.img, schreibe ${cfg.bootPartition} ..."
          dd if="$IMG" of="${cfg.bootPartition}" bs=4096 conv=fsync
          echo "$SUM" > /var/lib/xiaomi-begonia-boot.sha256
        fi
      '';
    })
  ];
}
