{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-sm8250 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/SM8250"
      "projects/ROCKNIX/packages/linux/patches/7.2"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8250"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
    ];
    hash = "sha256-9Ox2liSB8UQFDCjCJoP0Ps1TxtByiId72n/etYDycHY=";
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
    patchesFromDir "${rocknix-sm8250}/projects/ROCKNIX/packages/linux/patches/7.2"
    ++ patchesFromDir "${rocknix-sm8250}/projects/ROCKNIX/devices/SM8250/patches/linux";

  sm8250Dtbs = [
    "sm8250-ayn-thorlite.dtb"
    "sm8250-mangmi-air-y-pro.dtb"
    "sm8250-mangmi-pocket-max.dtb"
    "sm8250-retroidpocket-flip2-visionox.dtb"
    "sm8250-retroidpocket-flip2.dtb"
    "sm8250-retroidpocket-rp5-visionox.dtb"
    "sm8250-retroidpocket-rp5.dtb"
    "sm8250-retroidpocket-rpmini.dtb"
    "sm8250-retroidpocket-rpminiv2.dtb"
  ];

  linux_sm8250 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        BT_LE = lib.mkForce yes;
        CMA_SIZE_MBYTES = lib.mkForce (lib.kernel.freeform "256");
        JOYSTICK_RETROID = module;
        JOYSTICK_MANGMI_POCKET_MAX = module;
        INPUT_QCOM_SPMI_HAPTICS = yes;
        INPUT_PM8XXX_VIBRATOR = module;
        INPUT_PWM_VIBRA = module;
        DRM_PANEL_CHIPONE_ICNA35XX = module;
        DRM_PANEL_DDIC_CH13726A = module;
        DRM_PANEL_MANGMI_AIR_Y_PRO = module;
        DRM_PANEL_VISIONOX_VTDR6130_COG = module;
        BACKLIGHT_PWM = module;
        BACKLIGHT_QCOM_WLED = module;
        REGULATOR_QCOM_LCDB = yes;
        REGULATOR_QCOM_RPMH = yes;
        REGULATOR_QCOM_USB_VBUS = module;
        CHARGER_HL7139 = yes;
        CHARGER_QCOM_SMB5 = yes;
        BATTERY_QCOM_FG = yes;
        LEDS_AW200XX = module;
        LEDS_GROUP_MULTICOLOR = module;
        LEDS_HTR3212 = module;
        LEDS_QCOM_LPG = module;
        TOUCHSCREEN_EDT_FT5X06 = module;
        TOUCHSCREEN_HYNITRON_CST66XX = module;
        SENSORS_PWM_FAN = module;
        BT_HCIUART = module;
        BT_HCIUART_SERDEV = yes;
        BT_HCIUART_QCA = yes;
        POWER_SEQUENCING = yes;
        POWER_SEQUENCING_QCOM_WCN = module;
        ATH11K = module;
        ATH11K_PCI = module;
        PCI_PWRCTRL_PWRSEQ = module;
        TYPEC_FUSB302 = module;
        TYPEC_QCOM_PMIC = module;
        TYPEC_MUX_FSA4480 = module;
        TYPEC_MUX_GPIO_SBU = module;
        TYPEC_DP_ALTMODE = module;
        UCSI_PMIC_GLINK = module;
        QCOM_PMIC_GLINK = module;
        EXTCON_QCOM_SPMI_MISC = module;
        PINCTRL_SM8250 = yes;
        PINCTRL_SM8250_LPASS_LPI = module;
        SM_CAMCC_8250 = module;
        SM_DISPCC_8250 = yes;
        SM_GCC_8250 = yes;
        SM_GPUCC_8250 = yes;
        SM_VIDEOCC_8250 = yes;
        CLK_GFM_LPASS_SM8250 = module;
        INTERCONNECT_QCOM_SM8250 = yes;
        SND_SOC_AW88166 = module;
        SND_SOC_AW88395_LIB = module;
        SND_SOC_WCD938X = module;
        SND_SOC_WCD938X_SDW = module;
        SND_SOC_WSA881X = module;
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
        SOUNDWIRE_QCOM = module;
        SLIMBUS = module;
        SLIM_QCOM_NGD_CTRL = module;
        VIDEO_QCOM_IRIS = module;
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
          cp -v ${rocknix-sm8250}/projects/ROCKNIX/devices/SM8250/linux/dts/qcom/*.dts* arch/arm64/boot/dts/qcom/
          if ! grep -q "sm8250-retroidpocket-rp5.dtb" arch/arm64/boot/dts/qcom/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_QCOM) += ${lib.concatStringsSep " " sm8250Dtbs}" >> arch/arm64/boot/dts/qcom/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_sm8250
