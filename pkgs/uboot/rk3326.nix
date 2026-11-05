{
  lib,
  buildUBoot,
  rkbin,
}:
(buildUBoot {
  defconfig = "odroid-go2_defconfig";
  extraConfig = ''
    CONFIG_ROCKCHIP_EXTERNAL_TPL=y
    CONFIG_TPL_MAX_SIZE=0x4000
  '';
  extraMeta = {
    platforms = [ "aarch64-linux" ];
    maintainers = with lib.maintainers; [ flexiondotorg ];
  };
  env = {
    BL31 = "${rkbin}/bin/rk33/rk3326_bl31_v1.34.elf";
    ROCKCHIP_TPL = "${rkbin}/bin/rk33/rk3326_ddr_333MHz_v2.11.bin";
  };
  filesToInstall = [
    "u-boot.itb"
    "idbloader.img"
    "u-boot-rockchip.bin"
  ];
}).overrideAttrs
  (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i 's/return -ENODEV;/return OGA_V11;/' board/hardkernel/odroid_go2/go2.c
    '';
  })
