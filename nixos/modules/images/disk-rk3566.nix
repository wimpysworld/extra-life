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

      LABEL powkiddy-rgb20sx
        MENU LABEL Extra Life (Powkiddy RGB20SX)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3566-powkiddy-rgb20sx.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    '';

  extlinuxConf = mkExtlinuxConf "extlinux.conf" "extra-life";
  extlinuxConfPowkiddyRgb20sx = mkExtlinuxConf "extlinux-powkiddy-rgb20sx.conf" "powkiddy-rgb20sx";
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
      "/extlinux/extlinux-powkiddy-rgb20sx.conf".source = extlinuxConfPowkiddyRgb20sx;
      "/dtbs/rockchip".source = "${config.hardware.deviceTree.package}/rockchip";
      "/uboot/anbernic-rgxx3-u-boot-rockchip.bin".source =
        "${pkgs.ubootAnbernicRgxx3}/u-boot-rockchip.bin";
      "/uboot/powkiddy-x55-u-boot-rockchip.bin".source = "${pkgs.ubootPowkiddyX55}/u-boot-rockchip.bin";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build = {
    diskImage = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootAnbernicRgxx3}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImagePowkiddyRgb20sx = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfPowkiddyRgb20sx;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootAnbernicRgxx3}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImagePowkiddyX55 = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootPowkiddyX55}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });
  };
}
