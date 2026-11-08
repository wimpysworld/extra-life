{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-rk3326 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/RK3326"
      "projects/ROCKNIX/packages/linux/patches/mainline"
      "projects/ROCKNIX/packages/linux/patches/mainline-rockchip"
      "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
      "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326"
    ];
    hash = "sha256-UYFpR602bB+sVNt00XDXr5ZhaSlmjCQkixtuZiwznu0=";
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

  rockchipPatchNames = [
    "001-power-supply-rk817-charger-Fix-NVRAM-SoC-Value.patch"
    "002-power-supply-rk817-battery-resolve-boot-soc-from-counter.patch"
    "005-power-supply-rk817-charger-correct-gauge-across-sleep.patch"
    "006-dt-bindings-power-supply-rk817-charger-add-rockchip-gate-function-disable.patch"
    "007-power-supply-rk817-clear-sys-can-sd-register-by-default.patch"
    "008-power-supply-rk817-bound-the-boot-soc-with-the-ocv-table.patch"
  ];

  devicePatchNames = [
    "0008-mmc-sd-retry-a-failed-resume-after-a-power-cycle.patch"
    "001-panel-updates.patch"
    "002-gpiolib-of-legacy-api.patch"
    "003-input-add-input-polldev-driver.patch"
    "003-usb-dwc2-gadget-fix-null-deref-on-register-restore.patch"
    "004-input-drivers.patch"
    "004-usb-dwc2-skip-pm-callbacks-after-failed-core-reset.patch"
    "005-unigue-gpio-guid.patch"
    "007-ogs-panel-timings.patch"
    "008-esp-8089-wifi.patch"
    "010-dwc2-track-vbus-supply-state.patch"
    "023-px30s-tsadc-support.patch"
    "024-px30s-gpu-power-domain-workaround.patch"
    "025-px30s-dsi-dphy-timing-table.patch"
    "026-px30s-cpuinfo-soc-detection.patch"
    "027-px30s-io-domain-pmuio1.patch"
    "028-px30s-usb2phy-tuning.patch"
    "030-pwm-vibra-kick-stuck-boot-state.patch"
    "031-px30s-suspend-wakeup-config.patch"
    "032-px30s-otp-read-protocol.patch"
    "033-px30s-ddrphy-clock-topology.patch"
    "034-px30s-cru-suspend-resume-restore.patch"
    "035-dwc2-release-vbus-supply-on-role-switch.patch"
    "036-px30-dmc-devfreq.patch"
    "037-px30-dmc-pass-dram-settings-to-bl31.patch"
    "038-dwc2-no-pullup-on-id-change-without-gadget.patch"
    "039-drm-rockchip-vop-add-afbc-support-for-px30.patch"
  ];

  rocknixPatches =
    mkPatches "${rocknix-rk3326}/projects/ROCKNIX/packages/linux/patches/mainline" mainlinePatchNames
    ++ mkPatches "${rocknix-rk3326}/projects/ROCKNIX/packages/linux/patches/mainline-rockchip" rockchipPatchNames
    ++ mkPatches "${rocknix-rk3326}/projects/ROCKNIX/devices/RK3326/patches/linux" devicePatchNames;

  rk3326Dtbs = [
    "rk3326-anbernic-rg351m.dtb"
    "rk3326-anbernic-rg351v.dtb"
    "rk3326-batlexp-g350.dtb"
    "rk3326-gameconsole-eeclone.dtb"
    "rk3326-gameconsole-r33s.dtb"
    "rk3326-gameconsole-r36s.dtb"
    "rk3326-gameforce-chi.dtb"
    "rk3326-magicx-xu10.dtb"
    "rk3326-magicx-xu-mini-m.dtb"
    "rk3326-odroid-go2.dtb"
    "rk3326-odroid-go2-v11.dtb"
    "rk3326-odroid-go3.dtb"
    "rk3326-powkiddy-rgb10.dtb"
    "rk3326-powkiddy-rgb10x.dtb"
    "rk3326-powkiddy-rgb20s.dtb"
    "rk3326s-gkd-pixel2.dtb"
  ];

  linux_rk3326 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        ARM_PX30_DMC_DEVFREQ = yes;
        DEVFREQ_EVENT_ROCKCHIP_DFI = yes;
        DRM_PANEL_ELIDA_KD35T133 = module;
        DRM_PANEL_NEWVISION_NV3051D = module;
        DRM_PANEL_SITRONIX_ST7701 = module;
        DRM_PANEL_SITRONIX_ST7703 = module;
        ESP8089 = module;
        IIO = yes;
        INPUT_FF_MEMLESS = yes;
        INPUT_POLLDEV = yes;
        INPUT_PWM_VIBRA = module;
        JOYSTICK_ADC = module;
        JOYSTICK_GAMEFORCE_CHI = no;
        JOYSTICK_ODROIDGO2 = yes;
        JOYSTICK_ODROIDGO2_V11 = yes;
        JOYSTICK_ODROIDGO3 = yes;
        JOYSTICK_RGB20S = yes;
        JOYSTICK_XU10 = yes;
        KEYBOARD_ADC = yes;
        KEYBOARD_GPIO = yes;
        ROCKCHIP_CPUINFO = yes;
        ROCKCHIP_PM_CONFIG = yes;
        ROCKCHIP_SARADC = yes;
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
          cp -v ${rocknix-rk3326}/projects/ROCKNIX/packages/linux-drivers/generic-dsi/sources/panel-generic-dsi.c drivers/gpu/drm/panel/panel-generic-dsi.c
          if ! grep -q "panel-generic-dsi.o" drivers/gpu/drm/panel/Makefile; then
            echo "obj-y += panel-generic-dsi.o" >> drivers/gpu/drm/panel/Makefile
          fi
          cp -v ${rocknix-joypad}/rocknix-joypad.h ${rocknix-joypad}/rocknix-joypad.c ${rocknix-joypad}/rocknix-singleadc-joypad.c drivers/input/joystick/
          if ! grep -q "rocknix-singleadc-joypad.o" drivers/input/joystick/Makefile; then
            echo "obj-y += rocknix-joypad.o rocknix-singleadc-joypad.o" >> drivers/input/joystick/Makefile
          fi
          # Overwrite rk3326.dtsi and rk3326-odroid-go.dtsi alongside the 16 board
          # .dts files and ROCKNIX .dtsi includes: the board trees reference &dmc
          # and &dfi from ROCKNIX's rk3326.dtsi and replace mainline gpio-keys in
          # rk3326-odroid-go.dtsi with rocknix-joypad / odroidgo2-joypad nodes.
          cp -vf ${rocknix-rk3326}/projects/ROCKNIX/devices/RK3326/linux/dts/rockchip/*.dts* arch/arm64/boot/dts/rockchip/
          if ! grep -q "rk3326-gameconsole-r36s.dtb" arch/arm64/boot/dts/rockchip/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += ${lib.concatStringsSep " " rk3326Dtbs}" >> arch/arm64/boot/dts/rockchip/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_rk3326
