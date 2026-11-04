{
  lib,
  buildUBoot,
  armTrustedFirmwareRK3568,
  rkbin,
  rocknix-rk3566,
}:
(buildUBoot {
  defconfig = "anbernic-rgxx3-rk3566_defconfig";
  extraPatches = [
    "${rocknix-rk3566}/projects/ROCKNIX/devices/RK3566/packages/u-boot-Generic/patches/0003-board-rockchip-Fix-panel-detection-logic-for-mainlin.patch"
    "${rocknix-rk3566}/projects/ROCKNIX/devices/RK3566/packages/u-boot-Generic/patches/004-rgb20pro.patch"
  ];
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
}).overrideAttrs
  (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      cat > dts/upstream/src/arm64/rockchip/rk3566-powkiddy-rgb20-pro.dts << 'EOF'
      // SPDX-License-Identifier: (GPL-2.0+ OR MIT)

      /dts-v1/;

      #include "rk3566-powkiddy-rk2023.dts"

      / {
      	model = "Powkiddy RGB20 Pro";
      	compatible = "powkiddy,rgb20-pro", "rockchip,rk3566";
      };
      EOF
      sed -i 's|^CONFIG_OF_LIST="\(.*\)"|CONFIG_OF_LIST="\1 rockchip/rk3566-powkiddy-rgb20-pro"|' configs/anbernic-rgxx3-rk3566_defconfig
    '';
  })
