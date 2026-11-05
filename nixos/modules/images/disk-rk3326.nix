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

      LABEL hardkernel-odroid-go-advance
        MENU LABEL Extra Life (Hardkernel Odroid Go Advance)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-odroid-go2.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL hardkernel-odroid-go-advance-v11
        MENU LABEL Extra Life (Hardkernel Odroid Go Advance Black Edition)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-odroid-go2-v11.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL hardkernel-odroid-go-super
        MENU LABEL Extra Life (Hardkernel Odroid Go Super)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-odroid-go3.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg351m
        MENU LABEL Extra Life (Anbernic RG351M)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-anbernic-rg351m.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL anbernic-rg351v
        MENU LABEL Extra Life (Anbernic RG351V)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-anbernic-rg351v.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL gameconsole-r33s
        MENU LABEL Extra Life (GameConsole R33S)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-gameconsole-r33s.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL gameconsole-r36s
        MENU LABEL Extra Life (GameConsole R36S)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-gameconsole-r36s.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}

      LABEL powkiddy-rgb20s
        MENU LABEL Extra Life (Powkiddy RGB20S)
        LINUX /KERNEL
        INITRD /INITRD
        FDT /dtbs/rockchip/rk3326-powkiddy-rgb20s.dtb
        APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    '';

  extlinuxConf = mkExtlinuxConf "extlinux.conf" "extra-life";
  extlinuxConfOdroidGoAdvance = mkExtlinuxConf "extlinux-hardkernel-odroid-go-advance.conf" "hardkernel-odroid-go-advance";
  extlinuxConfOdroidGoAdvanceV11 = mkExtlinuxConf "extlinux-hardkernel-odroid-go-advance-v11.conf" "hardkernel-odroid-go-advance-v11";
  extlinuxConfOdroidGoSuper = mkExtlinuxConf "extlinux-hardkernel-odroid-go-super.conf" "hardkernel-odroid-go-super";
  extlinuxConfAnbernicRg351m = mkExtlinuxConf "extlinux-anbernic-rg351m.conf" "anbernic-rg351m";
  extlinuxConfAnbernicRg351v = mkExtlinuxConf "extlinux-anbernic-rg351v.conf" "anbernic-rg351v";
  extlinuxConfGameconsoleR33s = mkExtlinuxConf "extlinux-gameconsole-r33s.conf" "gameconsole-r33s";
  extlinuxConfGameconsoleR36s = mkExtlinuxConf "extlinux-gameconsole-r36s.conf" "gameconsole-r36s";
  extlinuxConfPowkiddyRgb20s = mkExtlinuxConf "extlinux-powkiddy-rgb20s.conf" "powkiddy-rgb20s";
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
      "/extlinux/extlinux-hardkernel-odroid-go-advance.conf".source = extlinuxConfOdroidGoAdvance;
      "/extlinux/extlinux-hardkernel-odroid-go-advance-v11.conf".source = extlinuxConfOdroidGoAdvanceV11;
      "/extlinux/extlinux-hardkernel-odroid-go-super.conf".source = extlinuxConfOdroidGoSuper;
      "/extlinux/extlinux-anbernic-rg351m.conf".source = extlinuxConfAnbernicRg351m;
      "/extlinux/extlinux-anbernic-rg351v.conf".source = extlinuxConfAnbernicRg351v;
      "/extlinux/extlinux-gameconsole-r33s.conf".source = extlinuxConfGameconsoleR33s;
      "/extlinux/extlinux-gameconsole-r36s.conf".source = extlinuxConfGameconsoleR36s;
      "/extlinux/extlinux-powkiddy-rgb20s.conf".source = extlinuxConfPowkiddyRgb20s;
      "/dtbs/rockchip".source = "${config.hardware.deviceTree.package}/rockchip";
      "/uboot/rk3326-u-boot-rockchip.bin".source = "${pkgs.ubootRk3326}/u-boot-rockchip.bin";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build = {
    diskImage = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageAnbernicRg351m = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfAnbernicRg351m;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageAnbernicRg351v = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfAnbernicRg351v;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageGameconsoleR33s = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfGameconsoleR33s;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImageGameconsoleR36s = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfGameconsoleR36s;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });

    diskImagePowkiddyRgb20s = config.system.build.repartImage.overrideAttrs (oldAttrs: {
      finalPartitions = lib.recursiveUpdate oldAttrs.finalPartitions {
        "10-boot".contents."/extlinux/extlinux.conf".source = extlinuxConfPowkiddyRgb20s;
      };
      postBuild = (oldAttrs.postBuild or "") + ''
        dd if="${pkgs.ubootRk3326}/u-boot-rockchip.bin" \
          of="${config.image.baseName}.raw" \
          bs=512 seek=64 conv=notrunc
      '';
    });
  };
}
