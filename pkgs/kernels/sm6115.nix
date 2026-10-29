{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-sm6115 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/SM6115"
      "projects/ROCKNIX/packages/linux/patches/7.2"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
    ];
    hash = "sha256-4xnHG+Ix8s/nPWeoqKhy52G8+3hIVGHXUfxMntcZOYw=";
  },
}:
let
  patchesFromDir =
    dir:
    let
      entries = builtins.readDir dir;
      names = builtins.filter (
        n:
        lib.hasSuffix ".patch" n
        && n != "0011-thermal-adc-tm5-drop-iio-val-int-check.patch"
        && n != "9999-fix-rust-build-error.patch"
      ) (builtins.attrNames entries);
      sorted = builtins.sort builtins.lessThan names;
    in
    map (n: {
      name = n;
      patch = "${dir}/${n}";
    }) sorted;

  rocknixPatches =
    patchesFromDir "${rocknix-sm6115}/projects/ROCKNIX/packages/linux/patches/7.2"
    ++ patchesFromDir "${rocknix-sm6115}/projects/ROCKNIX/devices/SM6115/patches/linux";

  linux_sm6115 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        JOYSTICK_MANGMI = module;
        JOYSTICK_RSINPUT = module;
        DRM_PANEL_MANGMI_HX83112A = module;
        DRM_PANEL_MANGMI_BM5460BB1 = module;
        DRM_PANEL_MANGMI_GH7005 = module;
        DRM_PANEL_MANGMI_TD4310 = module;
        DRM_PANEL_RETROID_DUOLITE_BOTTOM = module;
        DRM_WL818S = module;
        BACKLIGHT_PWM = module;
        BACKLIGHT_QCOM_WLED = module;
        BACKLIGHT_WL818S = module;
        REGULATOR_AW37503 = yes;
        REGULATOR_QCOM_LCDB = yes;
        SND_SOC_AW88261 = module;
        SND_SOC_ES8326 = module;
        SND_SOC_SM8250 = module;
        SND_SOC_QCOM = module;
        SND_SOC_QCOM_COMMON = module;
        SND_SOC_QCOM_SDW = module;
        SND_SOC_QDSP6 = module;
        SND_SOC_LPASS_MACRO_COMMON = module;
        SND_SOC_LPASS_WSA_MACRO = module;
        SND_SOC_LPASS_VA_MACRO = module;
        SND_SOC_LPASS_RX_MACRO = module;
        SND_SOC_LPASS_TX_MACRO = module;
        BATTERY_CW221X = module;
        BATTERY_CX221X = module;
        CHARGER_BQ256XX = yes;
        CHARGER_QCOM_SMB2 = yes;
        LEDS_AW200XX = module;
        LEDS_GROUP_MULTICOLOR = module;
        LEDS_QCOM_LPG = module;
        TOUCHSCREEN_HIMAX_HX83112A = module;
        TOUCHSCREEN_HIMAX_HX83112B = module;
        TOUCHSCREEN_HX83112A = module;
        TOUCHSCREEN_HYNITRON_CSTXXX = module;
        TOUCHSCREEN_CST3530 = module;
        INPUT_PWM_VIBRA = module;
        PWM_CLK = module;
        SENSORS_GPIO_FAN = module;
        BT_HCIUART = module;
        BT_HCIUART_SERDEV = yes;
        BT_HCIUART_QCA = yes;
        POWER_SEQUENCING = yes;
        POWER_SEQUENCING_QCOM_WCN = module;
        ATH10K = module;
        ATH10K_CE = yes;
        ATH10K_SNOC = module;
        TYPEC_FUSB302 = module;
        PINCTRL_SM6115 = yes;
        PINCTRL_SM6115_LPASS_LPI = module;
        SM_DISPCC_6115 = yes;
        SM_GCC_6115 = yes;
        SM_GPUCC_6115 = yes;
        SM_LPASSCC_6115 = yes;
        INTERCONNECT_QCOM_SM6115 = yes;
        QCOM_PSCI_SUSPEND_FALLBACK = yes;
        VIDEO_QCOM_VENUS = module;
      };
      ignoreConfigErrors = true;
      extraMeta = {
        platforms = [ "aarch64-linux" ];
        maintainers = with lib.maintainers; [ flexiondotorg ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          cp -v ${rocknix-sm6115}/projects/ROCKNIX/devices/SM6115/linux/dts/qcom/*.dts* arch/arm64/boot/dts/qcom/
          if ! grep -q "sm6115-mangmi-air-x-mq65.dtb" arch/arm64/boot/dts/qcom/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_QCOM) += sm6115-mangmi-air-x-mq65.dtb sm6115-mangmi-air-x-mq66.dtb sm6115-mangmi-air-x-mq66b.dtb sm6115-mangmi-air-y.dtb" >> arch/arm64/boot/dts/qcom/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_sm6115
