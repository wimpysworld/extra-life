{
  lib,
  pkgs,
  ...
}:
let
  rocknixSm8550 = pkgs.rocknix-sm8550;

  rocknixExtraFirmware = pkgs.fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "extra-firmware";
    rev = "925dfb5efbe5d6c3ca654f81e3e1f367f8492777";
    sparseCheckout = [ "SM8550" ];
    hash = "sha256-udLTJoDBZxRAgsVbc2IhOgY94AHdCwNl0LKMjYLQMHY=";
  };

  sm8550Firmware =
    pkgs.runCommand "sm8550-firmware"
      {
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware"
        cp -a "${rocknixExtraFirmware}/SM8550/." "$out/lib/firmware/"
        chmod -R u+w "$out/lib/firmware"
      '';

  sm8550AlsaUcm =
    pkgs.runCommand "sm8550-alsa-ucm-conf"
      {
        nativeBuildInputs = [ pkgs.patch ];
      }
      ''
        mkdir -p "$out/share/alsa"
        for p in "${rocknixSm8550}"/projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8550/*.patch; do
          patch -d "$out/share/alsa" -p1 < "$p"
        done
        for conf in \
          ayaneo-AYANEOPocketS1K-.conf \
          ayaneo-AYANEOPocketS2K-.conf \
          ayaneo-AYANEOPocketSMini-.conf; do
          ln -sf ../../AYANEO/Pocket/AYANEO-Pocket.conf "$out/share/alsa/ucm2/conf.d/sm8550/$conf"
        done
        for conf in \
          ayn-AYNOdin2Mini-.conf \
          ayn-AYNOdin2Portal-.conf; do
          ln -sf ../../AYN/Odin2/AYN-Odin2.conf "$out/share/alsa/ucm2/conf.d/sm8550/$conf"
        done
      '';
in
{
  imports = [
    ./qcom-common.nix
  ];

  extraLife.variantId = lib.mkDefault "sm8550";

  boot = {
    kernelPackages = pkgs.linuxPackages_sm8550;

    kernelParams = [
      "video=efifb:off"
      "initcall_blacklist=simpledrm_platform_driver_init,efifb_driver_init,sysfb_init"
      "console=tty0"
      "allow_mismatched_32bit_el0"
      "fw_devlink.strict=1"
      "pcie_ports=compat"
      "irqaffinity=0-2"
      "cgroup.memory=nokmem,nosocket"
      "nosoftlockup"
      "usbcore.interrupt_interval_override=045e:028e:2"
      "gpt"
    ];

    initrd = {
      extraFirmwarePaths = [
        "qcom/a740_sqe.fw"
        "qcom/gmu_gen70200.bin"
        "qcom/sm8550/a740_zap.mbn"
      ];

      availableKernelModules = [
        "gpi"
        "bam_dma"
        "i2c_qcom_geni"
        "spi_geni_qcom"
        "qcom_pbs"
        "sgm3804_regulator"
        "gpio_pca953x"
        "phy_snps_eusb2"
        "phy_qcom_eusb2_repeater"
        "phy_qcom_edp"
        "phy_qcom_qmp_combo"
        "phy_qcom_qmp_pcie"
        "phy_qcom_qmp_ufs"
        "phy_qcom_qmp_usb"
        "phy_qcom_qmp_usbc"
        "rmtfs_mem"
        "qcom_pon"
        "rtc_pm8xxx"
        "fusb302"
        "qcom_pmic_tcpm"
        "typec"
        "tcpm"
        "llcc_qcom"
        "ocmem"
        "led_class_multicolor"
        "leds_qcom_lpg"
        "leds_htr3212"
        "leds_group_multicolor"
        "leds_pwm_multicolor"
        "pwm_sn3112"
        "pwm_bl"
        "qcom_wled"
        "odin2mini_backlight"
        "sy7758"
        "lontium_lt8912b"
        "simple_bridge"
        "display_connector"
        "panel_ar06_4inch"
        "panel_ar02_3inch"
        "panel_wt0600_2k"
        "panel_wt0600_1k"
        "panel_ar16_4inch"
        "panel_boe_xm91080g"
        "panel_chipone_icna35xx"
        "panel_ddic_ch13726a"
        "panel_ilitek_il97680a"
        "panel_sitronix_st7703"
        "panel_synaptics_td4328"
        "panel_visionox_vtdr6130_cog"
        "panel_edp"
        "panel_simple"
        "msm"
      ];

      kernelModules = [
        "gpi"
        "bam_dma"
        "i2c_qcom_geni"
        "spi_geni_qcom"
        "qcom_pbs"
        "sgm3804_regulator"
        "gpio_pca953x"
        "phy_snps_eusb2"
        "phy_qcom_eusb2_repeater"
        "phy_qcom_edp"
        "phy_qcom_qmp_combo"
        "phy_qcom_qmp_pcie"
        "phy_qcom_qmp_ufs"
        "phy_qcom_qmp_usb"
        "phy_qcom_qmp_usbc"
        "rmtfs_mem"
        "qcom_pon"
        "rtc_pm8xxx"
        "fusb302"
        "qcom_pmic_tcpm"
        "typec"
        "tcpm"
        "llcc_qcom"
        "ocmem"
        "led_class_multicolor"
        "leds_qcom_lpg"
        "leds_htr3212"
        "leds_group_multicolor"
        "leds_pwm_multicolor"
        "pwm_sn3112"
        "pwm_bl"
        "qcom_wled"
        "odin2mini_backlight"
        "sy7758"
        "lontium_lt8912b"
        "simple_bridge"
        "display_connector"
        "panel_ar06_4inch"
        "panel_ar02_3inch"
        "panel_wt0600_2k"
        "panel_wt0600_1k"
        "panel_ar16_4inch"
        "panel_boe_xm91080g"
        "panel_chipone_icna35xx"
        "panel_ddic_ch13726a"
        "panel_ilitek_il97680a"
        "panel_sitronix_st7703"
        "panel_synaptics_td4328"
        "panel_visionox_vtdr6130_cog"
        "panel_edp"
        "panel_simple"
        "msm"
      ];
    };

    kernelModules = [
      "gpi"
      "bam_dma"
      "i2c_qcom_geni"
      "spi_geni_qcom"
      "qcom_pbs"
      "sgm3804_regulator"
      "gpio_pca953x"
      "phy_snps_eusb2"
      "phy_qcom_eusb2_repeater"
      "phy_qcom_edp"
      "phy_qcom_qmp_combo"
      "phy_qcom_qmp_pcie"
      "phy_qcom_qmp_ufs"
      "phy_qcom_qmp_usb"
      "phy_qcom_qmp_usbc"
      "rmtfs_mem"
      "qcom_pon"
      "rtc_pm8xxx"
      "qcom_spmi_adc5"
      "qcom_spmi_temp_alarm"
      "qcom_iris"
      "venus_core"
      "venus_dec"
      "venus_enc"
      "llcc_qcom"
      "ocmem"
      "led_class_multicolor"
      "leds_qcom_lpg"
      "leds_htr3212"
      "leds_group_multicolor"
      "leds_pwm_multicolor"
      "pwm_sn3112"
      "pwm_bl"
      "qcom_wled"
      "odin2mini_backlight"
      "sy7758"
      "lontium_lt8912b"
      "simple_bridge"
      "display_connector"
      "panel_ar06_4inch"
      "panel_ar02_3inch"
      "panel_wt0600_2k"
      "panel_wt0600_1k"
      "panel_ar16_4inch"
      "panel_boe_xm91080g"
      "panel_chipone_icna35xx"
      "panel_ddic_ch13726a"
      "panel_ilitek_il97680a"
      "panel_sitronix_st7703"
      "panel_synaptics_td4328"
      "panel_visionox_vtdr6130_cog"
      "panel_edp"
      "panel_simple"
      "msm"
      "pwrseq_qcom_wcn"
      "pci_pwrctrl_pwrseq"
      "ath12k"
      "xhci_pci_renesas"
      "r8152"
      "cdc_ether"
      "r8153_ecm"
      "fusb302"
      "qcom_pmic_tcpm"
      "typec"
      "tcpm"
      "fsa4480"
      "gpio_sbu_mux"
      "nb7vpq904m"
      "typec_displayport"
      "pmic_glink"
      "pmic_glink_altmode"
      "ucsi_glink"
      "pinctrl_sm8550_lpass_lpi"
      "hci_uart"
      "btqca"
      "rsinput"
      "qcom_hv_haptics"
      "pm8xxx_vibrator"
      "pwm_vibra"
      "pwm_fan"
      "rmi_core"
      "rmi_i2c"
      "synaptics_dsx"
      "goodix_ts"
      "hynitron_cstxxx"
      "hynitron_cst66xx"
      "edt_ft5x06"
      "soundwire_qcom"
      "slimbus"
      "slim_qcom_ngd_ctrl"
      "snd_soc_aw88166"
      "snd_soc_wcd938x"
      "snd_soc_wcd938x_sdw"
      "snd_soc_wsa884x"
      "snd_soc_sc8280xp"
      "snd_soc_qcom_common"
      "snd_soc_qcom_sdw"
      "snd_q6dsp_common"
      "gpr"
      "snd_q6apm"
      "q6apm_dai"
      "q6apm_lpass_dais"
      "q6prm"
      "q6prm_clocks"
      "snd_soc_lpass_wsa_macro"
      "snd_soc_lpass_va_macro"
      "snd_soc_lpass_rx_macro"
      "snd_soc_lpass_tx_macro"
    ];
  };

  hardware.firmware = [
    sm8550Firmware
  ];

  services = {
    inputplumber.enable = true;

    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    udev = {
      extraHwdb = builtins.readFile "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/lib/udev/hwdb.d/10-ayaneo.hwdb";

      extraRules = ''
        SUBSYSTEM=="input", ATTRS{name}=="AYN Odin2 Gamepad", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
        SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", ATTRS{name}=="qcom-hv-haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
        ACTION=="bind", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:010d:*", ATTR{power/control}="on"
        ACTION=="bind", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:0204:*", ATTR{power/control}="on"
      '';
    };
  };

  environment = {
    etc = {
      "inputplumber/devices.d/01-ayaneo-controller-japanese.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/devices/01-ayaneo-controller-japanese.yaml";
      "inputplumber/devices.d/01-ayaneo-controller.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/devices/01-ayaneo-controller.yaml";
      "inputplumber/devices.d/02-ayn-controller.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/devices/02-ayn-controller.yaml";
      "inputplumber/devices.d/02-ayn-thor-controller.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/devices/02-ayn-thor-controller.yaml";
      "inputplumber/capability_maps.d/ayaneo_mcu_japanese.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/capability_maps/ayaneo_mcu_japanese.yaml";
      "inputplumber/capability_maps.d/ayaneo_mcu_xbox.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/capability_maps/ayaneo_mcu_xbox.yaml";
      "inputplumber/capability_maps.d/ayaneo_pocketsmini_gpio.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/capability_maps/ayaneo_pocketsmini_gpio.yaml";
      "inputplumber/capability_maps.d/ayn_mcu.yaml".source =
        "${rocknixSm8550}/projects/ROCKNIX/devices/SM8550/filesystem/usr/share/inputplumber/capability_maps/ayn_mcu.yaml";
    };

    pathsToLink = [
      "/share/alsa/ucm2"
      "/share/inputplumber"
    ];

    systemPackages = [
      pkgs.alsa-ucm-conf
      sm8550AlsaUcm
    ];
  };
}
