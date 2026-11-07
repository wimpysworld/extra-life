{
  lib,
  fetchFromGitHub,
  linux_7_2,
  linuxPackagesFor,
  rocknix-sm8550 ? fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "distribution";
    rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
    sparseCheckout = [
      "projects/ROCKNIX/devices/SM8550"
      "projects/ROCKNIX/packages/linux/patches/7.2"
      "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8550"
    ];
    hash = "sha256-5Sb2DjyPyVSjR8iaUlUQBL+Lj8WhYnlq+aWpK2XpOHY=";
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
    patchesFromDir "${rocknix-sm8550}/projects/ROCKNIX/packages/linux/patches/7.2"
    ++ patchesFromDir "${rocknix-sm8550}/projects/ROCKNIX/devices/SM8550/patches/linux";

  sm8550Dtbs = [
    "qcs8550-ayaneo-pocketace.dtb"
    "qcs8550-ayaneo-pocketdmg.dtb"
    "qcs8550-ayaneo-pocketds.dtb"
    "qcs8550-ayaneo-pocketevo.dtb"
    "qcs8550-ayaneo-pockets1k.dtb"
    "qcs8550-ayaneo-pockets2k.dtb"
    "qcs8550-ayaneo-pocketsmini.dtb"
    "qcs8550-ayn-odin2.dtb"
    "qcs8550-ayn-odin2mini.dtb"
    "qcs8550-ayn-odin2portal.dtb"
    "qcs8550-ayn-thor.dtb"
    "qcs8550-retroidpocket-rp6-top-dpad.dtb"
    "qcs8550-retroidpocket-rp6.dtb"
    "qcs8550-retroidpocket-rpnova.dtb"
  ];

  linux_sm8550 =
    (linux_7_2.override {
      kernelPatches = (linux_7_2.kernelPatches or [ ]) ++ rocknixPatches;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        BT_LE = lib.mkForce yes;
        JOYSTICK_RSINPUT = module;
        INPUT_QCOM_HV_HAPTICS = module;
        INPUT_PM8XXX_VIBRATOR = module;
        INPUT_PWM_VIBRA = module;
        INPUT_MATRIXKMAP = yes;
        RMI4_CORE = module;
        RMI4_I2C = module;
        RMI4_F03 = yes;
        RMI4_F11 = yes;
        RMI4_F12 = yes;
        RMI4_F30 = yes;
        RMI4_F3A = yes;
        RMI4_F54 = yes;
        RMI4_F55 = yes;
        TOUCHSCREEN_EDT_FT5X06 = module;
        TOUCHSCREEN_GOODIX = module;
        TOUCHSCREEN_HYNITRON_CSTXXX = module;
        TOUCHSCREEN_HYNITRON_CST66XX = module;
        TOUCHSCREEN_SYNAPTICS_DSX = module;
        DRM_LONTIUM_LT8912B = module;
        DRM_SIMPLE_BRIDGE = module;
        DRM_DISPLAY_CONNECTOR = module;
        DRM_PANEL_AR06_4INCH = module;
        DRM_PANEL_AR02_3INCH = module;
        DRM_PANEL_AYANEO_WT0600_2K = module;
        DRM_PANEL_AYANEO_WT0600_1K = module;
        DRM_PANEL_AYANEO_AR16_4INCH = module;
        DRM_PANEL_BOE_XM91080G = module;
        DRM_PANEL_CHIPONE_ICNA35XX = module;
        DRM_PANEL_DDIC_CH13726A = module;
        DRM_PANEL_ILITEK_IL97680A = module;
        DRM_PANEL_SITRONIX_ST7703 = module;
        DRM_PANEL_SYNAPTICS_TD4328 = module;
        DRM_PANEL_VISIONOX_VTDR6130_COG = module;
        DRM_PANEL_EDP = module;
        DRM_PANEL_SIMPLE = module;
        BACKLIGHT_ODIN2MINI = module;
        BACKLIGHT_PWM = module;
        BACKLIGHT_QCOM_WLED = module;
        BACKLIGHT_SY7758 = module;
        PWM_SN3112 = module;
        REGULATOR_QCOM_RPMH = yes;
        REGULATOR_QCOM_USB_VBUS = module;
        REGULATOR_SGM3804 = module;
        GPIO_PCA953X = module;
        LEDS_GROUP_MULTICOLOR = module;
        LEDS_HTR3212 = module;
        LEDS_PWM_MULTICOLOR = module;
        LEDS_QCOM_LPG = module;
        SENSORS_PWM_FAN = module;
        BT_HCIUART = module;
        BT_HCIUART_SERDEV = yes;
        BT_HCIUART_QCA = yes;
        POWER_SEQUENCING = yes;
        POWER_SEQUENCING_QCOM_WCN = module;
        ATH12K = module;
        PCI_PWRCTRL_PWRSEQ = module;
        USB_XHCI_PCI_RENESAS = module;
        USB_RTL8152 = module;
        USB_RTL8153_ECM = module;
        TYPEC_FUSB302 = module;
        TYPEC_QCOM_PMIC = module;
        TYPEC_UCSI = module;
        UCSI_PMIC_GLINK = module;
        QCOM_PMIC_GLINK = module;
        QCOM_PD_MAPPER = yes;
        QCOM_PDR_HELPERS = yes;
        QCOM_SMEM = yes;
        QCOM_SOCINFO = yes;
        QCOM_SPMI_ADC_TM5 = yes;
        QRTR = yes;
        QRTR_SMD = yes;
        QRTR_TUN = yes;
        QRTR_MHI = yes;
        BATTERY_QCOM_BATTMGR = module;
        UHID = yes;
        HID_PLAYSTATION = module;
        PLAYSTATION_FF = yes;
        TYPEC_MUX_FSA4480 = module;
        TYPEC_MUX_GPIO_SBU = module;
        TYPEC_MUX_NB7VPQ904M = module;
        TYPEC_DP_ALTMODE = module;
        PHY_SNPS_EUSB2 = yes;
        PHY_QCOM_EUSB2_REPEATER = yes;
        PHY_QCOM_EDP = module;
        PHY_QCOM_QMP_COMBO = module;
        PHY_QCOM_QMP_PCIE = module;
        PHY_QCOM_QMP_UFS = module;
        PHY_QCOM_QMP_USB = module;
        NVMEM_QCOM_QFPROM = yes;
        NVMEM_QCOM_SEC_QFPROM = yes;
        NVMEM_SPMI_SDAM = yes;
        PINCTRL_SM8550 = yes;
        PINCTRL_LPASS_LPI = module;
        PINCTRL_SM8550_LPASS_LPI = module;
        SM_CAMCC_8550 = module;
        SM_DISPCC_8550 = yes;
        SM_GCC_8550 = yes;
        SM_GPUCC_8550 = yes;
        SM_TCSRCC_8550 = yes;
        SM_VIDEOCC_8550 = yes;
        SPMI_PMIC_CLKDIV = yes;
        INTERCONNECT_QCOM_SM8550 = yes;
        SND_SOC_AW88166 = module;
        SND_SOC_AW88395_LIB = module;
        SND_SOC_WCD938X = module;
        SND_SOC_WCD938X_SDW = module;
        SND_SOC_WSA884X = module;
        SND_SOC_SC8280XP = module;
        SND_SOC_QCOM = module;
        SND_SOC_QCOM_COMMON = module;
        SND_SOC_QCOM_SDW = module;
        SND_SOC_QDSP6 = module;
        SND_SOC_QDSP6_APRV2_RPMSG = module;
        SND_SOC_QDSP6_GPR_RPMSG = module;
        SND_SOC_QDSP6_APM = module;
        SND_SOC_QDSP6_APM_DAI = module;
        SND_SOC_QDSP6_APM_LPASS_DAI = module;
        SND_SOC_QDSP6_PRM = module;
        SND_SOC_QDSP6_PRM_LPASS_CLOCKS = module;
        SND_SOC_LPASS_MACRO_COMMON = module;
        SND_SOC_LPASS_WSA_MACRO = module;
        SND_SOC_LPASS_VA_MACRO = module;
        SND_SOC_LPASS_RX_MACRO = module;
        SND_SOC_LPASS_TX_MACRO = module;
        SOUNDWIRE = module;
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
          cp -v ${rocknix-sm8550}/projects/ROCKNIX/devices/SM8550/linux/dts/qcom/*.dts* arch/arm64/boot/dts/qcom/
          if ! grep -q "qcs8550-ayn-odin2.dtb" arch/arm64/boot/dts/qcom/Makefile; then
            echo "dtb-\$(CONFIG_ARCH_QCOM) += ${lib.concatStringsSep " " sm8550Dtbs}" >> arch/arm64/boot/dts/qcom/Makefile
          fi
        '';
      });
in
linuxPackagesFor linux_sm8550
