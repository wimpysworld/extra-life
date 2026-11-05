{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-rk3588 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/RK3588"
      "projects/ROCKNIX/packages/linux/patches/mainline"
      "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
    ];
    hash = "sha256-EkE55LsnGQifC2j1s9wdejuqKHg2kUyT8gwe+GB9RgM=";
  },
  rocknix-joypad ? fetchFromGitHub {
    owner = "hackbar";
    repo = "rocknix-joypad";
    rev = "005033d1ddd8746c771f2c81f1174f2d892541c9";
    hash = "sha256-uprZYBDSjmSP0+MRK4e0mkRrij84zYg6eb5wtAtYsLo=";
  },
}:
let
  patchesFromDir =
    dir:
    let
      entries = builtins.readDir dir;
      names = builtins.filter (n: lib.hasSuffix ".patch" n) (builtins.attrNames entries);
      sorted = builtins.sort builtins.lessThan names;
    in
    map (n: {
      name = n;
      patch = "${dir}/${n}";
    }) sorted;

  devicePatchDir = "${rocknix-rk3588}/projects/ROCKNIX/devices/RK3588/patches/linux";

  devicePatchNames = [
    "004-battery-name.patch"
    "012-Multiaxis.patch"
  ];

  rocknixPatches =
    patchesFromDir "${rocknix-rk3588}/projects/ROCKNIX/packages/linux/patches/mainline"
    ++ map (n: {
      name = n;
      patch = "${devicePatchDir}/${n}";
    }) devicePatchNames;

  rk3588Dtbs = [
    "rk3588s-retro-lite-cm5.dtb"
    "rk3588-retro-lite-cm5.dtb"
    "rk3588s-retroled-cm5.dtb"
    "rk3588-retroled-cm5.dtb"
  ];

  linux_rk3588 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        DRM_PANTHOR = module;
        DRM_ROCKCHIP = module;
        ROCKCHIP_VOP2 = yes;
        ROCKCHIP_DW_HDMI_QP = yes;
        ROCKCHIP_DW_MIPI_DSI2 = yes;
        ROCKCHIP_DW_DP = yes;
        PHY_ROCKCHIP_SAMSUNG_HDPTX = module;
        PHY_ROCKCHIP_NANENG_COMBOPHY = module;
        PHY_ROCKCHIP_USBDP = module;
        PHY_ROCKCHIP_INNO_USB2 = module;
        MFD_RK8XX_SPI = yes;
        REGULATOR_RK808 = yes;
        PINCTRL_RK806 = yes;
        REGULATOR_RK860X = yes;
        BATTERY_CW2015 = module;
        BATTERY_MAX17042 = module;
        CHARGER_BQ257XX = module;
        CHARGER_GPIO = module;
        TYPEC_FUSB302 = module;
        TI_ADS1015 = module;
        ROCKCHIP_SARADC = module;
        JOYSTICK_ADC = module;
        KEYBOARD_ADC = module;
        KEYBOARD_GPIO = module;
        INPUT_PWM_VIBRA = module;
        PWM_GPIO = module;
        SENSORS_PWM_FAN = module;
        TOUCHSCREEN_GOODIX = module;
        RTC_DRV_HYM8563 = module;
        SND_SOC_ROCKCHIP_I2S_TDM = module;
        SND_SOC_ES8328 = module;
        SND_SOC_ES8328_I2C = module;
        SND_SOC_WM8960 = module;
        SND_SOC_SIMPLE_AMPLIFIER = module;
      };
      ignoreConfigErrors = true;
      extraMeta = {
        platforms = [ "aarch64-linux" ];
        maintainers = with lib.maintainers; [ flexiondotorg ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          cp -v ${rocknix-rk3588}/projects/ROCKNIX/packages/linux-drivers/generic-dsi/sources/panel-generic-dsi.c drivers/gpu/drm/panel/panel-generic-dsi.c
          sed -i '/generic_panel_of_match\[\] = {/a \	{ .compatible = "huiling,hl055fhav028c" },\n\	{ .compatible = "raydium,rm67199" },' drivers/gpu/drm/panel/panel-generic-dsi.c
          if ! grep -q "panel-generic-dsi.o" drivers/gpu/drm/panel/Makefile; then
            echo "obj-y += panel-generic-dsi.o" >> drivers/gpu/drm/panel/Makefile
          fi
          cp -v ${rocknix-joypad}/rocknix-joypad.h ${rocknix-joypad}/rocknix-joypad.c drivers/input/joystick/
          if ! grep -q "rocknix-joypad.o" drivers/input/joystick/Makefile; then
            echo "obj-y += rocknix-joypad.o" >> drivers/input/joystick/Makefile
          fi
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588s-retro-lite-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-radxa-cm5-io.dts"

          / {
          	model = "Retro Lite CM5";
          	compatible = "retro-lite,cm5", "radxa,cm5-io", "radxa,cm5", "rockchip,rk3588s";
          };
          EOF
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588-retro-lite-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-radxa-cm5-io.dts"

          / {
          	model = "Retro Lite CM5";
          	compatible = "retro-lite,cm5", "radxa,cm5-io", "radxa,cm5", "rockchip,rk3588";
          };
          EOF
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588s-retroled-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-radxa-cm5-io.dts"

          / {
          	model = "RetrOLED CM5";
          	compatible = "retroled,cm5", "radxa,cm5-io", "radxa,cm5", "rockchip,rk3588s";
          };
          EOF
          cat << 'EOF' > arch/arm64/boot/dts/rockchip/rk3588-retroled-cm5.dts
          // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
          /dts-v1/;

          #include "rk3588s-radxa-cm5-io.dts"

          / {
          	model = "RetrOLED CM5";
          	compatible = "retroled,cm5", "radxa,cm5-io", "radxa,cm5", "rockchip,rk3588";
          };
          EOF
          if ! grep -q "rk3588s-retro-lite-cm5.dtb" arch/arm64/boot/dts/rockchip/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += ${lib.concatStringsSep " " rk3588Dtbs}" >> arch/arm64/boot/dts/rockchip/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_rk3588
