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

      LABEL anbernic-rg35xx-plus
        MENU LABEL Extra Life (Anbernic RG35XX Plus)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-plus.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-plus-rev6-panel
        MENU LABEL Extra Life (Anbernic RG35XX Plus Rev 6 Panel)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-plus-rev6-panel.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-2024
        MENU LABEL Extra Life (Anbernic RG35XX 2024)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-2024.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-2024-rev6-panel
        MENU LABEL Extra Life (Anbernic RG35XX 2024 Rev 6 Panel)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-2024-rev6-panel.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-pro
        MENU LABEL Extra Life (Anbernic RG35XX Pro)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-pro.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    '';

  extlinuxConf = mkExtlinuxConf "extlinux.conf" "anbernic-rg35xx-plus";
  extlinuxConfAnbernicRg35xxPlus = mkExtlinuxConf "extlinux-anbernic-rg35xx-plus.conf" "anbernic-rg35xx-plus";
  extlinuxConfAnbernicRg35xxPlusRev6 = mkExtlinuxConf "extlinux-anbernic-rg35xx-plus-rev6-panel.conf" "anbernic-rg35xx-plus-rev6-panel";
  extlinuxConfAnbernicRg35xx2024 = mkExtlinuxConf "extlinux-anbernic-rg35xx-2024.conf" "anbernic-rg35xx-2024";
  extlinuxConfAnbernicRg35xx2024Rev6 = mkExtlinuxConf "extlinux-anbernic-rg35xx-2024-rev6-panel.conf" "anbernic-rg35xx-2024-rev6-panel";
  extlinuxConfAnbernicRg35xxPro = mkExtlinuxConf "extlinux-anbernic-rg35xx-pro.conf" "anbernic-rg35xx-pro";

  mkH700DiskImage =
    defaultExtlinuxConf:
    config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = defaultExtlinuxConf;
      };
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
        config.extraLife.buildHostPkgs.gptfdisk
      ];
      postBuild = (oldAttrs.postBuild or "") + ''
        sgdisk -d 1 -j 2016 -h 2:3 "${config.image.baseName}.raw"
        dd if="${pkgs.ubootAnbernicH700}/u-boot-sunxi-with-spl.bin" \
          of="${config.image.baseName}.raw" \
          bs=1024 seek=8 conv=notrunc
      '';
    });
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
      "/extlinux/extlinux-anbernic-rg35xx-plus.conf".source = extlinuxConfAnbernicRg35xxPlus;
      "/extlinux/extlinux-anbernic-rg35xx-plus-rev6-panel.conf".source =
        extlinuxConfAnbernicRg35xxPlusRev6;
      "/extlinux/extlinux-anbernic-rg35xx-2024.conf".source = extlinuxConfAnbernicRg35xx2024;
      "/extlinux/extlinux-anbernic-rg35xx-2024-rev6-panel.conf".source =
        extlinuxConfAnbernicRg35xx2024Rev6;
      "/extlinux/extlinux-anbernic-rg35xx-pro.conf".source = extlinuxConfAnbernicRg35xxPro;
      "/dtbs/allwinner".source = "${config.hardware.deviceTree.package}/allwinner";
      "/uboot/anbernic-h700-u-boot-sunxi-with-spl.bin".source =
        "${pkgs.ubootAnbernicH700}/u-boot-sunxi-with-spl.bin";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build = {
    diskImage = mkH700DiskImage extlinuxConfAnbernicRg35xxPlus;
    diskImageAnbernicRg35xxPlus = mkH700DiskImage extlinuxConfAnbernicRg35xxPlus;
    diskImageAnbernicRg35xx2024 = mkH700DiskImage extlinuxConfAnbernicRg35xx2024;
    diskImageAnbernicRg35xxPro = mkH700DiskImage extlinuxConfAnbernicRg35xxPro;
  };
}
