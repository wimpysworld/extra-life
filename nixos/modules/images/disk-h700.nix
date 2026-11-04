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

      LABEL anbernic-rg35xx-h
        MENU LABEL Extra Life (Anbernic RG35XX H)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-h.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-h-rev6-panel
        MENU LABEL Extra Life (Anbernic RG35XX H Rev 6 Panel)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-h-rev6-panel.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-sp
        MENU LABEL Extra Life (Anbernic RG35XX SP)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-sp.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg35xx-sp-v2-panel
        MENU LABEL Extra Life (Anbernic RG35XX SP V2 Panel)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg35xx-sp-v2-panel.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg-sp
        MENU LABEL Extra Life (Anbernic RG SP)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/allwinner/sun50i-h700-anbernic-rg-sp.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    '';

  extlinuxConf = mkExtlinuxConf "extlinux.conf" "anbernic-rg35xx-plus";
  extlinuxConfAnbernicRg35xxPlus = mkExtlinuxConf "extlinux-anbernic-rg35xx-plus.conf" "anbernic-rg35xx-plus";
  extlinuxConfAnbernicRg35xxPlusRev6 = mkExtlinuxConf "extlinux-anbernic-rg35xx-plus-rev6-panel.conf" "anbernic-rg35xx-plus-rev6-panel";
  extlinuxConfAnbernicRg35xx2024 = mkExtlinuxConf "extlinux-anbernic-rg35xx-2024.conf" "anbernic-rg35xx-2024";
  extlinuxConfAnbernicRg35xx2024Rev6 = mkExtlinuxConf "extlinux-anbernic-rg35xx-2024-rev6-panel.conf" "anbernic-rg35xx-2024-rev6-panel";
  extlinuxConfAnbernicRg35xxPro = mkExtlinuxConf "extlinux-anbernic-rg35xx-pro.conf" "anbernic-rg35xx-pro";
  extlinuxConfAnbernicRg35xxH = mkExtlinuxConf "extlinux-anbernic-rg35xx-h.conf" "anbernic-rg35xx-h";
  extlinuxConfAnbernicRg35xxHRev6 = mkExtlinuxConf "extlinux-anbernic-rg35xx-h-rev6-panel.conf" "anbernic-rg35xx-h-rev6-panel";
  extlinuxConfAnbernicRg35xxSp = mkExtlinuxConf "extlinux-anbernic-rg35xx-sp.conf" "anbernic-rg35xx-sp";
  extlinuxConfAnbernicRg35xxSpV2 = mkExtlinuxConf "extlinux-anbernic-rg35xx-sp-v2-panel.conf" "anbernic-rg35xx-sp-v2-panel";
  extlinuxConfAnbernicRgSp = mkExtlinuxConf "extlinux-anbernic-rg-sp.conf" "anbernic-rg-sp";

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
      "/extlinux/extlinux-anbernic-rg35xx-h.conf".source = extlinuxConfAnbernicRg35xxH;
      "/extlinux/extlinux-anbernic-rg35xx-h-rev6-panel.conf".source = extlinuxConfAnbernicRg35xxHRev6;
      "/extlinux/extlinux-anbernic-rg35xx-sp.conf".source = extlinuxConfAnbernicRg35xxSp;
      "/extlinux/extlinux-anbernic-rg35xx-sp-v2-panel.conf".source = extlinuxConfAnbernicRg35xxSpV2;
      "/extlinux/extlinux-anbernic-rg-sp.conf".source = extlinuxConfAnbernicRgSp;
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
    diskImageAnbernicRg35xxH = mkH700DiskImage extlinuxConfAnbernicRg35xxH;
    diskImageAnbernicRg35xxSp = mkH700DiskImage extlinuxConfAnbernicRg35xxSp;
  };
}
