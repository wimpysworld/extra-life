{
  config,
  lib,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;

  mkExtlinuxConf =
    name: defaultLabel:
    pkgs.writeText name ''
      DEFAULT ${defaultLabel}
      TIMEOUT 0

      LABEL extra-life
        MENU LABEL Extra Life
        LINUX /KERNEL
        INITRD /INITRD
        FDTDIR /dtbs
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL gameforce-ace
        MENU LABEL Extra Life (GameForce ACE)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3588s-gameforce-ace.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL orangepi-5
        MENU LABEL Extra Life (Orange Pi 5)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3588s-orangepi-5.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL retro-lite-cm5
        MENU LABEL Extra Life (Retro Lite CM5)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3588-retro-lite-cm5.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL retroled-cm5
        MENU LABEL Extra Life (RetroLED CM5)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3588-retroled-cm5.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    '';

  extlinuxConf = mkExtlinuxConf "extlinux.conf" "extra-life";
  extlinuxConfGameforceAce = mkExtlinuxConf "extlinux-gameforce-ace.conf" "gameforce-ace";
  extlinuxConfOrangepi5 = mkExtlinuxConf "extlinux-orangepi-5.conf" "orangepi-5";
  extlinuxConfRetroLiteCm5 = mkExtlinuxConf "extlinux-retro-lite-cm5.conf" "retro-lite-cm5";
  extlinuxConfRetroledCm5 = mkExtlinuxConf "extlinux-retroled-cm5.conf" "retroled-cm5";
in
{
  imports = [
    ./disk-base.nix
  ];

  image.repart.partitions = {
    "05-uboot".repartConfig = {
      Type = "linux-generic";
      Format = "empty";
      SizeMinBytes = "16M";
      SizeMaxBytes = "16M";
    };
    "10-boot".contents = {
      "/extlinux/extlinux.conf".source = extlinuxConf;
      "/extlinux/extlinux-gameforce-ace.conf".source = extlinuxConfGameforceAce;
      "/extlinux/extlinux-orangepi-5.conf".source = extlinuxConfOrangepi5;
      "/extlinux/extlinux-retro-lite-cm5.conf".source = extlinuxConfRetroLiteCm5;
      "/extlinux/extlinux-retroled-cm5.conf".source = extlinuxConfRetroledCm5;
      "/dtbs/rockchip".source = "${config.hardware.deviceTree.package}/rockchip";
      "/uboot/rk3588-u-boot-rockchip.bin".source = "${pkgs.ubootRk3588}/u-boot-rockchip.bin";
      "/uboot/orangepi-5-u-boot-rockchip.bin".source = "${pkgs.ubootRk3588}/u-boot-rockchip.bin";
      "/uboot/gameforce-ace-u-boot-rockchip.bin".source = "${pkgs.ubootGameforceAce}/u-boot-rockchip.bin";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build = {
    diskImage = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3588}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageGameforceAce = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfGameforceAce;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootGameforceAce}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageOrangepi5 = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfOrangepi5;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3588}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageRetroLiteCm5 = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfRetroLiteCm5;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3588}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageRetroledCm5 = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfRetroledCm5;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3588}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });
  };
}
