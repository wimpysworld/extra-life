{
  config,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;

  extlinuxConf = pkgs.writeText "extlinux.conf" ''
    DEFAULT extra-life
    TIMEOUT 0

    LABEL extra-life
      MENU LABEL Extra Life
      LINUX /KERNEL
      INITRD /INITRD
      FDTDIR /dtbs
      APPEND init=/nix/store/current-system/init ${toString config.boot.kernelParams}
  '';
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
      "/dtbs/allwinner".source = "${config.hardware.deviceTree.package}/allwinner";
      "/uboot/anbernic-h700-u-boot-sunxi-with-spl.bin".source =
        "${pkgs.ubootAnbernicH700}/u-boot-sunxi-with-spl.bin";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build.diskImage = config.system.build.repartImage.overrideAttrs (oldAttrs: {
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
}
