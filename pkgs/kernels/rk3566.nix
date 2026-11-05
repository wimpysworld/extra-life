{
  lib,
  fetchFromGitHub,
  linux_6_18,
  linuxPackagesFor,
  rocknix-rk3566 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/RK3566"
      "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
      "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/rtl_bt"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326"
    ];
    hash = "sha256-pI/gC+HxASbVF/XwBI4qMrWSATB3lfaV2MVjzCAdAD4=";
  },
}:
let
  patchDir = "${rocknix-rk3566}/projects/ROCKNIX/devices/RK3566/patches/linux";

  patchNames = [
    "0003-drm-panel-st7703-Fix-Panel-Initialization-for-Anbern.patch"
    "0004-arm64-dts-rockchip-fix-wifi-sdio-errors.patch"
    "0005-arm64-dts-rockchip-fixup-anbernic-controls.patch"
    "0006-drm-panel-nv3051d-fix-panel-timings-and-display-mode.patch"
    "0008-mmc-sd-retry-a-failed-resume-after-a-power-cycle.patch"
    "0009-arm64-dts-rockchip-fix-shoulders-triggers-on-powkidd.patch"
    "0010-drm-panel-st7703-request-higher-pixelclock-for-RGB30.patch"
    "0013-Bluetooth-Check-key-sizes-only-when-Secure-Simple-Pa.patch"
    "0014-drm-panel-st7701-fixup-Anbernic-RG-Arc-panel-timings.patch"
    "0015-arm64-dts-rockchip-use-linear-backlight-levels-to-im.patch"
    "0016-arm64-dts-rockchip-add-device-tree-for-powkiddy-x35s.patch"
    "0018-arm64-dts-rockchip-add-device-tree-for-powkiddy-rgb2.patch"
    "0019-arm64-dts-rockchip-add-system-power-controller-attri.patch"
    "0021-arm64-dts-rockchip-fix-missing-dma-names.patch"
    "0024-sdmmc1-card-detect-delay.patch"
    "0025-arc-swap-touch-axes.patch"
    "0028-regulator-fan53555-accept-the-STI8070A-on-the-Silergy-path.patch"
    "0029-anbernic-fix-adc-key.patch"
    "1001-arm64-dts-rockchip-Add-idle-states-for-rk356x.patch"
    "1002-arm64-dts-rockchip-Add-spk_amp-regulator-for-Anberni.patch"
    "1004-arm64-dts-rockchip-Add-avdd_0v9-and-avdd_1v8-for-RGx.patch"
    "1006-arm64-dts-rockchip-Correct-boot-enabled-regulators-f.patch"
    "1008-arm64-dts-rockchip-Enable-DMA-for-uart1-on-RGxx3.patch"
    "1009-arm64-dts-rockchip-Map-wifi-host-wake-interrupt-for-.patch"
    "1011-input-touchscreen-goodix-usability-fixes.patch"
  ];

  rocknixPatches = map (n: {
    name = n;
    patch = "${patchDir}/${n}";
  }) patchNames;

  linux_rk3566 =
    (linux_6_18.override {
      kernelPatches = (linux_6_18.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        BT_HCIUART = module;
        BT_HCIUART_SERDEV = yes;
        BT_HCIUART_3WIRE = yes;
        BT_HCIUART_RTL = yes;
        INPUT_PWM_VIBRA = module;
        REGULATOR_FAN53555 = yes;
      };
      extraMeta = {
        platforms = [ "aarch64-linux" ];
        maintainers = with lib.maintainers; [ flexiondotorg ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          cp -v ${rocknix-rk3566}/projects/ROCKNIX/packages/linux-drivers/generic-dsi/sources/panel-generic-dsi.c drivers/gpu/drm/panel/panel-generic-dsi.c
          if ! grep -q "panel-generic-dsi.o" drivers/gpu/drm/panel/Makefile; then
            echo "obj-y += panel-generic-dsi.o" >> drivers/gpu/drm/panel/Makefile
          fi
          if ! grep -q "rk3566-powkiddy-rgb20-pro.dtb" arch/arm64/boot/dts/rockchip/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3566-powkiddy-rgb20-pro.dtb rk3566-powkiddy-x35s.dtb" >> arch/arm64/boot/dts/rockchip/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_rk3566
