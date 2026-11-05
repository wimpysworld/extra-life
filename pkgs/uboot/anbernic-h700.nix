{
  lib,
  buildUBoot,
  armTrustedFirmwareAllwinnerH616,
  rocknix-h700,
}:
(buildUBoot {
  defconfig = "anbernic_rg35xx_h700_defconfig";
  extraPatches = [
    "${rocknix-h700}/projects/ROCKNIX/devices/H700/packages/u-boot-DDR4/patches/0001-Update-dram_sun50i_h616.c.patch"
    "${rocknix-h700}/projects/ROCKNIX/devices/H700/packages/u-boot-DDR4/patches/0002-sunxi-axp717-charge-only-boot.patch"
  ];
  extraMeta = {
    platforms = [ "aarch64-linux" ];
    maintainers = with lib.maintainers; [ flexiondotorg ];
  };
  env = {
    BL31 = "${armTrustedFirmwareAllwinnerH616}/bl31.bin";
  };
  filesToInstall = [
    "u-boot-sunxi-with-spl.bin"
  ];
}).overrideAttrs
  (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      cp -v ${rocknix-h700}/projects/ROCKNIX/devices/H700/packages/u-boot-DDR4/sources/configs/anbernic_rg35xx_h700_lpddr4_defconfig configs/anbernic_rg35xx_h700_defconfig
    '';
  })
