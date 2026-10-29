{
  lib,
  buildUBoot,
  armTrustedFirmwareRK3568,
  rkbin,
}:
buildUBoot {
  defconfig = "anbernic-rgxx3-rk3566_defconfig";
  extraMeta = {
    platforms = [ "aarch64-linux" ];
    maintainers = with lib.maintainers; [ flexiondotorg ];
  };
  env = {
    BL31 = "${armTrustedFirmwareRK3568}/bl31.elf";
    ROCKCHIP_TPL = rkbin.TPL_RK3566;
  };
  filesToInstall = [
    "u-boot.itb"
    "idbloader.img"
    "u-boot-rockchip.bin"
  ];
}
