{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-h700 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/H700"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/H700"
      "projects/ROCKNIX/packages/linux/patches/mainline"
      "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
    ];
    hash = "sha256-+W507E7TEarFyQqhkpu+hrYhrI/7HKXZG06YuwxajRo=";
  },
  rocknix-joypad ? fetchFromGitHub {
    owner = "hackbar";
    repo = "rocknix-joypad";
    rev = "005033d1ddd8746c771f2c81f1174f2d892541c9";
    hash = "sha256-uprZYBDSjmSP0+MRK4e0mkRrij84zYg6eb5wtAtYsLo=";
  },
}:
let
  mkPatches =
    dir: names:
    map (n: {
      name = n;
      patch = "${dir}/${n}";
    }) names;

  mainlinePatchNames = [
    "0003-pwm-add-pwm_set_period.patch"
    "0004-input-adc-keys-redirect-keycode-316-to-rocknix-joypa.patch"
    "0005-Bluetooth-btrtl-Add-the-support-for-RTL8733BU.patch"
  ];

  # 0003-Update-sun8i_tcon_top.c.patch is applied via substituteInPlace in
  # postPatch; 0204-dts-Enable-hdmi-sound.patch depends on disabled 0203.
  devicePatchNames = [
    "0002-rg35xx-enable-HDMI-LCD.patch"
    "0007-rg35xx-add-GPU-opp.patch"
    "0008-v8_20260804_james_hilliard1_introduce_allwinner_h616_pwm_controller.patch"
    "0010-rg35xx-enable-pwm-backlight.patch"
    "0040-Revert-usb-musb-Fix-hardware-lockup-on-first-Rx-endp.patch"
    "0110-v2_20250226_kikuchan98_drm_panel_add_generic_mipi_panel_driver.patch"
    "0111-rg35xx-2024-use-panel-mipi-dpi-spi-driver.patch"
    "0124-battery-name.patch"
    "0126-20241018_macroalpha82_rg35xx_add_additional_hardware_support.patch"
    "0127-enable-mmc1-for-RG35XX-2024.patch"
    "0140-rg35xx-2024-use-rocknix-joypad-driver.patch"
    "0144-Update-sun50i-h700-anbernic-rg35xx-h.dts.patch"
    "0150-add-forcefeedback.patch"
    "0151-phy-fix-OTG-host-mode.patch"
    "0152-rg35xx-2024-enable-usb-otg.patch"
    "0153-enable-rgb-leds.patch"
    "0154-rocknix-dt-id.patch"
    "0155-sun4i-set-rgb-connector-as-DSI.patch"
    "0156-rg35xx-plus-add-pcf8563-rtc.patch"
    "0157-input-axp20x-pek-do-not-report-the-key-press-that-woke-the-system.patch"
    "0158-mmc-sunxi-mmc-mask-data0-when-updating-the-clock-on-h616-emmc.patch"
    "0159-arm64-dts-rg35xx-2024-keep-the-second-sd-card-powered.patch"
    "0160-phy-sun4i-usb-disable-the-clock-that-was-enabled.patch"
    "0161-drm-sun4i-gate-the-display-pipeline-across-system-suspend.patch"
    "0162-pinctrl-sunxi-release-the-lcd0-pads-while-the-panel-is-off.patch"
    "0163-asoc-sun4i-codec-suspend-the-codec-and-switch-the-amplifier-supply.patch"
    "0200-h700-update-opps.patch"
    "0210-h616-cpu-opp-mark-480MHz-as-suspend-opp.patch"
    "0901-dts-rg35xx-2024-fix-led-1-color.patch"
  ];

  rocknixPatches =
    mkPatches "${rocknix-h700}/projects/ROCKNIX/packages/linux/patches/mainline" mainlinePatchNames
    ++ mkPatches "${rocknix-h700}/projects/ROCKNIX/devices/H700/patches/linux" devicePatchNames;

  h700Dtbs = [
    "sun50i-h700-anbernic-rg-sp.dtb"
    "sun50i-h700-anbernic-rg28xx.dtb"
    "sun50i-h700-anbernic-rg34xx.dtb"
    "sun50i-h700-anbernic-rg34xx-sp.dtb"
    "sun50i-h700-anbernic-rg34xx-sp-v2-panel.dtb"
    "sun50i-h700-anbernic-rg35xx-2024-rev6-panel.dtb"
    "sun50i-h700-anbernic-rg35xx-h-rev6-panel.dtb"
    "sun50i-h700-anbernic-rg35xx-plus-rev6-panel.dtb"
    "sun50i-h700-anbernic-rg35xx-pro.dtb"
    "sun50i-h700-anbernic-rg35xx-sp-v2-panel.dtb"
    "sun50i-h700-anbernic-rg40xx-h.dtb"
    "sun50i-h700-anbernic-rg40xx-h-v2-panel.dtb"
    "sun50i-h700-anbernic-rg40xx-v.dtb"
    "sun50i-h700-anbernic-rg40xx-v-v2-panel.dtb"
    "sun50i-h700-anbernic-rgcubexx.dtb"
  ];

  linux_h700 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        ARCH_SUNXI = yes;
        SUN50I_DE2_BUS = yes;
        SUN50I_H616_CCU = yes;
        SUN50I_H6_PRCM_PPU = yes;
        SUN50I_H6_R_CCU = yes;
        SUN50I_IOMMU = yes;
        SUN8I_DE2_CCU = yes;
        SUN8I_R_CCU = yes;
        SUN8I_THERMAL = yes;
        DRM_SUN4I = yes;
        DRM_SUN50I_PLANES = yes;
        DRM_SUN8I_DW_HDMI = yes;
        DRM_SUN8I_MIXER = yes;
        DRM_SUN8I_TCON_TOP = yes;
        DRM_PANFROST = module;
        DRM_PANEL_MIPI = yes;
        PWM_SUN4I = yes;
        PWM_SUN8I = yes;
        BACKLIGHT_GPIO = yes;
        BACKLIGHT_PWM = yes;
        SPI_BITBANG = yes;
        SPI_GPIO = yes;
        SPI_SUN6I = yes;
        SUN20I_GPADC = yes;
        INPUT_FF_MEMLESS = yes;
        MFD_AXP20X = yes;
        MFD_AXP20X_I2C = yes;
        MFD_AXP20X_RSB = yes;
        REGULATOR_AXP20X = yes;
        AXP20X_ADC = yes;
        AXP20X_POWER = yes;
        BATTERY_AXP20X = yes;
        CHARGER_AXP20X = yes;
        INPUT_AXP20X_PEK = yes;
        MMC_SUNXI = yes;
        PHY_SUN4I_USB = yes;
        USB_MUSB_HDRC = yes;
        USB_MUSB_SUNXI = yes;
        USB_EHCI_HCD = yes;
        USB_EHCI_HCD_PLATFORM = yes;
        USB_OHCI_HCD = yes;
        USB_OHCI_HCD_PLATFORM = yes;
        RTC_DRV_PCF8563 = yes;
        KEYBOARD_ADC = yes;
        KEYBOARD_GPIO = yes;
        IIO = yes;
        IIO_MUX = module;
        MUX_GPIO = module;
        SND_SUN4I_CODEC = module;
        SND_SUN4I_I2S = module;
        SND_SUN4I_SPDIF = module;
        RTW88 = module;
        RTW88_CORE = module;
        RTW88_SDIO = module;
        RTW88_8821C = module;
        RTW88_8821CS = module;
        BT_HCIUART = module;
        BT_HCIUART_SERDEV = yes;
        BT_HCIUART_3WIRE = yes;
        BT_HCIUART_RTL = yes;
      };
      # nixpkgs's generic common-config.nix sets desktop/x86 options whose
      # transitive Kconfig dependencies differ on patched ARM SoC trees.
      ignoreConfigErrors = true;
      extraMeta = {
        platforms = [ "aarch64-linux" ];
        maintainers = with lib.maintainers; [ flexiondotorg ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace drivers/gpu/drm/sun4i/sun8i_tcon_top.c \
            --replace-fail "writel(0, regs + TCON_TOP_PORT_SEL_REG);" "writel(0x20, regs + TCON_TOP_PORT_SEL_REG);"
          sed -i '/reg_vcc5v0_usb: regulator-vcc5v0-usb {/,/^\t};/d; /usb1_vbus-supply = <&reg_vcc5v0_usb>;/d' \
            arch/arm64/boot/dts/allwinner/sun50i-h700-anbernic-rg35xx-h.dts
          cp -v ${rocknix-h700}/projects/ROCKNIX/devices/H700/linux/dts/allwinner/*.dts arch/arm64/boot/dts/allwinner/
          if ! grep -q "sun50i-h700-anbernic-rg-sp.dtb" arch/arm64/boot/dts/allwinner/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_SUNXI) += ${lib.concatStringsSep " " h700Dtbs}" >> arch/arm64/boot/dts/allwinner/Makefile
          fi
          cp -v ${rocknix-joypad}/rocknix-joypad.h ${rocknix-joypad}/rocknix-singleadc-joypad.c drivers/input/joystick/
          if ! grep -q "rocknix-singleadc-joypad.o" drivers/input/joystick/Makefile; then
            echo "obj-y += rocknix-singleadc-joypad.o" >> drivers/input/joystick/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_h700
