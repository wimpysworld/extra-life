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

  rocknixPatches =
    patchesFromDir "${rocknix-rk3326}/projects/ROCKNIX/packages/linux/patches/mainline"
    ++ patchesFromDir "${rocknix-rk3326}/projects/ROCKNIX/packages/linux/patches/mainline-rockchip"
    ++ patchesFromDir "${rocknix-rk3326}/projects/ROCKNIX/devices/RK3326/patches/linux";

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
        INPUT_POLLDEV = yes;
        INPUT_PWM_VIBRA = module;
        JOYSTICK_ADC = module;
        JOYSTICK_GAMEFORCE_CHI = yes;
        JOYSTICK_ODROIDGO2 = yes;
        JOYSTICK_ODROIDGO2_V11 = yes;
        JOYSTICK_ODROIDGO3 = yes;
        JOYSTICK_RGB20S = yes;
        JOYSTICK_XU10 = yes;
        ROCKCHIP_CPUINFO = yes;
        ROCKCHIP_PM_CONFIG = yes;
        ROCKCHIP_SARADC = yes;
      };
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
          cp -vf ${rocknix-rk3326}/projects/ROCKNIX/devices/RK3326/linux/dts/rockchip/*.dts* arch/arm64/boot/dts/rockchip/
          if ! grep -q "rk3326-gameconsole-r36s.dtb" arch/arm64/boot/dts/rockchip/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += ${lib.concatStringsSep " " rk3326Dtbs}" >> arch/arm64/boot/dts/rockchip/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_rk3326
