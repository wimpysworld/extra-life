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
      "/dtbs/rockchip".source = "${config.hardware.deviceTree.package}/rockchip";
      "/KERNEL".source = "${toplevel}/kernel";
      "/INITRD".source = "${toplevel}/initrd";
      "/SYSTEM".source = config.system.build.systemSquashfs;
    };
  };

  system.build.diskImage = config.image.repart.image.overrideAttrs (oldAttrs: {
    postBuild = (oldAttrs.postBuild or "") + ''
      dd if="${pkgs.ubootAnbernicRgxx3}/u-boot-rockchip.bin" \
        of="${config.image.baseName}.raw" \
        bs=512 seek=64 conv=notrunc
    '';
  });
}
