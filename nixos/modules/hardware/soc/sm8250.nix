{
  lib,
  pkgs,
  ...
}:
let
  rocknixSm8250 = pkgs.rocknix-sm8250;

  rocknixExtraFirmware = pkgs.fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "extra-firmware";
    rev = "925dfb5efbe5d6c3ca654f81e3e1f367f8492777";
    sparseCheckout = [ "SM8250" ];
    hash = "sha256-7GsKC1YZLo6l93/y/9TYXD+l0HLSc3Zl+ut19cckfuk=";
  };

  compressedLinuxFirmware = pkgs.compressFirmwareZstd pkgs.linux-firmware;

  sm8250Firmware =
    pkgs.runCommand "sm8250-firmware"
      {
        nativeBuildInputs = [ pkgs.zstd ];
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/qcom/sm8250"
        cp -a "${rocknixExtraFirmware}/SM8250/." "$out/lib/firmware/"
        chmod -R u+w "$out/lib/firmware"
        cp -Lv "${compressedLinuxFirmware}/lib/firmware/qcom/sm8250/Thundercomm/RB5/slpi.mbn.zst" \
          "$out/lib/firmware/qcom/sm8250/slpi.mbn.zst"
        for jsn in adspr.jsn adspua.jsn cdspr.jsn; do
          zstd -d -f "${compressedLinuxFirmware}/lib/firmware/qcom/sm8250/$jsn.zst" \
            -o "$out/lib/firmware/qcom/sm8250/$jsn"
        done
        for jsn in slpir.jsn slpius.jsn; do
          zstd -d -f "${compressedLinuxFirmware}/lib/firmware/qcom/sm8250/Thundercomm/RB5/$jsn.zst" \
            -o "$out/lib/firmware/qcom/sm8250/$jsn"
        done
      '';

  sm8250AlsaUcm =
    pkgs.runCommand "sm8250-alsa-ucm-conf"
      {
        nativeBuildInputs = [ pkgs.patch ];
      }
      ''
        mkdir -p "$out/share/alsa/ucm2/Qualcomm/sm8250"
        mkdir -p "$out/share/alsa/ucm2/conf.d/sm8250"
        mkdir -p "$out/share/alsa/ucm2/codecs/wsa881x"
        for p in "${rocknixSm8250}"/projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8250/*.patch; do
          patch -d "$out/share/alsa" -p1 < "$p"
        done
        cp -a "${rocknixSm8250}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm8250/." \
          "$out/share/alsa/ucm2/Qualcomm/sm8250/"
        cp -a "${rocknixSm8250}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm8250/." \
          "$out/share/alsa/ucm2/conf.d/sm8250/"
      '';
in
{
  imports = [
    ./qcom-common.nix
  ];

  extraLife.variantId = lib.mkDefault "sm8250";

  boot = {
    kernelPackages = pkgs.linuxPackages_sm8250;

    kernelParams = [
      "video=efifb:off"
      "initcall_blacklist=simpledrm_platform_driver_init,efifb_driver_init,sysfb_init"
      "console=tty0"
      "gpt"
    ];

    initrd = {
      extraFirmwarePaths = [
        "qcom/a650_sqe.fw"
        "qcom/a650_gmu.bin"
        "qcom/sm8250/a650_zap.mbn"
      ];

      availableKernelModules = [
        "gpi"
        "bam_dma"
        "i2c_qcom_geni"
        "spi_geni_qcom"
        "qcom_pbs"
        "qcom_labibb_regulator"
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
        "leds_aw200xx"
        "leds_htr3212"
        "leds_group_multicolor"
        "pwm_bl"
        "qcom_wled"
        "panel_chipone_icna35xx"
        "panel_ddic_ch13726a"
        "panel_mangmi_air_y_pro"
        "panel_visionox_vtdr6130_cog"
        "msm"
      ];

      kernelModules = [
        "gpi"
        "bam_dma"
        "i2c_qcom_geni"
        "spi_geni_qcom"
        "qcom_pbs"
        "qcom_labibb_regulator"
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
        "leds_aw200xx"
        "leds_htr3212"
        "leds_group_multicolor"
        "pwm_bl"
        "qcom_wled"
        "panel_chipone_icna35xx"
        "panel_ddic_ch13726a"
        "panel_mangmi_air_y_pro"
        "panel_visionox_vtdr6130_cog"
        "msm"
      ];
    };

    kernelModules = [
      "gpi"
      "bam_dma"
      "i2c_qcom_geni"
      "spi_geni_qcom"
      "qcom_pbs"
      "qcom_labibb_regulator"
      "phy_qcom_qmp_combo"
      "phy_qcom_qmp_pcie"
      "phy_qcom_qmp_ufs"
      "phy_qcom_qmp_usb"
      "phy_qcom_qmp_usbc"
      "rmtfs_mem"
      "apr"
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
      "leds_aw200xx"
      "leds_htr3212"
      "leds_group_multicolor"
      "pwm_bl"
      "qcom_wled"
      "panel_chipone_icna35xx"
      "panel_ddic_ch13726a"
      "panel_mangmi_air_y_pro"
      "panel_visionox_vtdr6130_cog"
      "msm"
      "pwrseq_qcom_wcn"
      "pci_pwrctrl_pwrseq"
      "ath11k"
      "ath11k_pci"
      "fusb302"
      "qcom_pmic_tcpm"
      "fsa4480"
      "gpio_sbu_mux"
      "typec_displayport"
      "pmic_glink"
      "pmic_glink_altmode"
      "ucsi_glink"
      "pinctrl_sm8250_lpass_lpi"
      "lpass_gfm_sm8250"
      "hci_uart"
      "btqca"
      "retroid"
      "mangmi_pocket_max"
      "pm8xxx_vibrator"
      "pwm_vibra"
      "pwm_fan"
      "edt_ft5x06"
      "hynitron_cst66xx"
      "soundwire_qcom"
      "slimbus"
      "slim_qcom_ngd_ctrl"
      "snd_soc_aw88166"
      "snd_soc_wcd938x"
      "snd_soc_wcd938x_sdw"
      "snd_soc_wsa881x"
      "snd_soc_sm8250"
      "snd_soc_qcom_common"
      "snd_soc_qcom_sdw"
      "snd_q6dsp_common"
      "q6core"
      "q6afe"
      "q6afe_dai"
      "q6afe_clocks"
      "q6adm"
      "q6routing"
      "q6asm"
      "q6asm_dai"
      "snd_soc_lpass_wsa_macro"
      "snd_soc_lpass_va_macro"
      "snd_soc_lpass_rx_macro"
      "snd_soc_lpass_tx_macro"
    ];
  };

  hardware.firmware = [
    sm8250Firmware
  ];

  services.inputplumber.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTRS{name}=="Retroid Pocket Gamepad", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", ATTRS{name}=="pmi8998_haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
    SUBSYSTEM=="input", ATTRS{name}=="MANGMI Pocket Max Joypad", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
    ACTION=="bind", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:010d:*", ATTR{power/control}="on"
    ACTION=="bind", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:2010:*", ATTR{power/control}="on"
  '';

  environment = {
    etc = {
      "inputplumber/devices.d/01-retroid-controller.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/devices/01-retroid-controller.yaml";
      "inputplumber/devices.d/02-mangmi-pocket-max.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/devices/02-mangmi-pocket-max.yaml";
      "inputplumber/devices.d/03-mangmi-air-y-pro.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/devices/03-mangmi-air-y-pro.yaml";
      "inputplumber/capability_maps.d/retroid_mcu.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/capability_maps/retroid_mcu.yaml";
      "inputplumber/capability_maps.d/pocket_max_mcu.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/capability_maps/pocket_max_mcu.yaml";
      "inputplumber/capability_maps.d/air_y_pro_mcu.yaml".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/inputplumber/capability_maps/air_y_pro_mcu.yaml";
      "wireplumber/wireplumber.conf.d/51-ayn-thor-lite.conf".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/wireplumber/wireplumber.conf.d/51-ayn-thor-lite.conf";
      "wireplumber/wireplumber.conf.d/52-mangmi-hdmi.conf".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/wireplumber/wireplumber.conf.d/52-mangmi-hdmi.conf";
      "wireplumber/wireplumber.conf.d/52-pocket-max-headphones.conf".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/wireplumber/wireplumber.conf.d/52-pocket-max-headphones.conf";
      "wireplumber/wireplumber.conf.d/52-retroid-pocket-5-hdmi.conf".source =
        "${rocknixSm8250}/projects/ROCKNIX/devices/SM8250/filesystem/usr/share/wireplumber/wireplumber.conf.d/52-retroid-pocket-5-hdmi.conf";
    };

    pathsToLink = [
      "/share/alsa/ucm2"
      "/share/inputplumber"
    ];

    systemPackages = [
      pkgs.alsa-ucm-conf
      sm8250AlsaUcm
    ];
  };
}
