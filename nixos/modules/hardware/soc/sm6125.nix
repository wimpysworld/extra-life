{
  lib,
  pkgs,
  ...
}:
let
  rocknixSm6115 = pkgs.rocknix-sm6115;

  rocknixExtraFirmware = pkgs.fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "extra-firmware";
    rev = "925dfb5efbe5d6c3ca654f81e3e1f367f8492777";
    sparseCheckout = [ "SM6115" ];
    hash = "sha256-PIjDosffCpmxuPOcsHfXFRf49U2E0oiKwAdrYyP0wFI=";
  };

  compressedLinuxFirmware = pkgs.compressFirmwareZstd pkgs.linux-firmware;

  sm6125Firmware =
    pkgs.runCommand "sm6125-firmware"
      {
        nativeBuildInputs = [ pkgs.zstd ];
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/qcom/qrb4210"
        cp -a "${rocknixExtraFirmware}/SM6115/." "$out/lib/firmware/"
        chmod -R u+w "$out/lib/firmware"
        ln -sf qcom/sm6125/aw883xx_acf.bin "$out/lib/firmware/aw883xx_acf.bin"
        for jsn in adspr.jsn adsps.jsn adspua.jsn; do
          zstd -d -f "${compressedLinuxFirmware}/lib/firmware/qcom/qrb4210/$jsn.zst" \
            -o "$out/lib/firmware/qcom/qrb4210/$jsn"
        done
      '';

  sm6125AlsaUcm = pkgs.runCommand "sm6125-alsa-ucm-conf" { } ''
    mkdir -p "$out/share/alsa/ucm2/Qualcomm/sm6125"
    mkdir -p "$out/share/alsa/ucm2/conf.d/sm4250"
    mkdir -p "$out/share/alsa/ucm2/conf.d/qrb4210-rb2-snd"
    mkdir -p "$out/share/alsa/ucm2/conf.d/sm6125"
    mkdir -p "$out/share/alsa/ucm2/conf.d/sm8250"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6125/RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6125/RetroidPocketDuoLite.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6125/HiFi-RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6125/HiFi-RetroidPocketDuoLite.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/conf.d/sm4250/RetroidPocketDuoLite.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/conf.d/qrb4210-rb2-snd/RetroidPocketDuoLite.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/conf.d/sm6125/RetroidPocketDuoLite.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/RetroidPocketDuoLite.conf \
      "$out/share/alsa/ucm2/conf.d/sm8250/RetroidPocketDuoLite.conf"
  '';
in
{
  imports = [
    ./qcom-common.nix
  ];

  extraLife.variantId = lib.mkDefault "sm6125";

  boot = {
    kernelPackages = pkgs.linuxPackages_sm6115;

    kernelParams = [
      "video=efifb:off"
      "initcall_blacklist=simpledrm_platform_driver_init,efifb_driver_init,sysfb_init"
      "console=tty0"
      "gpt"
      "ssbd=force-off"
      "kpti=off"
      "cgroup.memory=nokmem,nosocket"
    ];

    initrd = {
      extraFirmwarePaths = [
        "qcom/a630_sqe.fw"
        "qcom/a630_gmu.bin"
        "qcom/qrb4210/a610_zap.mbn"
        "qcom/sm6125/a610_zap.mbn"
      ];

      availableKernelModules = [
        "gpi"
        "bam_dma"
        "i2c_qcom_geni"
        "spi_geni_qcom"
        "qcom_pbs"
        "qcom_labibb_regulator"
        "phy_qcom_qmp_combo"
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
        "leds_group_multicolor"
        "pwm_bl"
        "qcom_wled"
        "wl818s_bl"
        "wl818s"
        "panel_hx83112a"
        "panel_retroid_duolite_bottom"
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
        "leds_group_multicolor"
        "pwm_bl"
        "qcom_wled"
        "wl818s_bl"
        "wl818s"
        "panel_hx83112a"
        "panel_retroid_duolite_bottom"
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
      "phy_qcom_qmp_usbc"
      "rmtfs_mem"
      "apr"
      "qcom_pon"
      "rtc_pm8xxx"
      "qcom_spmi_adc5"
      "qcom_spmi_temp_alarm"
      "venus_core"
      "venus_dec"
      "venus_enc"
      "llcc_qcom"
      "ocmem"
      "led_class_multicolor"
      "leds_qcom_lpg"
      "leds_aw200xx"
      "leds_group_multicolor"
      "pwm_bl"
      "qcom_wled"
      "wl818s_bl"
      "wl818s"
      "panel_hx83112a"
      "panel_retroid_duolite_bottom"
      "msm"
      "pwrseq_qcom_wcn"
      "ath10k_core"
      "ath10k_snoc"
      "fusb302"
      "qcom_pmic_tcpm"
      "pinctrl_sm6115_lpass_lpi"
      "hci_uart"
      "btqca"
      "rsinput"
      "aw86927"
      "pwm_vibra"
      "pwm_clk"
      "pwm_fan"
      "gpio_fan"
      "cw221x_battery"
      "himax_hx83112a"
      "himax_hx83112b"
      "edt_ft5x06"
      "hynitron_cstxxx"
      "soundwire_qcom"
      "snd_soc_aw88166"
      "snd_soc_wcd937x"
      "snd_soc_wcd937x_sdw"
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
      "snd_soc_lpass_va_macro"
      "snd_soc_lpass_rx_macro"
      "snd_soc_lpass_tx_macro"
    ];
  };

  hardware.firmware = [
    sm6125Firmware
  ];

  services = {
    cage.environment = {
      EXTRA_LIFE_PRIMARY_OUTPUT = "DSI-1";
      EXTRA_LIFE_SECONDARY_OUTPUT = "DP-1";
      EXTRA_LIFE_SECONDARY_PANEL_ORIENTATION = "normal";
      EXTRA_LIFE_TOP_PANEL = "duolite-hx83112a";
      EXTRA_LIFE_BOTTOM_PANEL = "duolite-bottom-panel";
    };

    inputplumber.enable = true;

    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    udev.extraRules = ''
      SUBSYSTEM=="input", ATTRS{name}=="Retroid Pocket Duo Lite Gamepad", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
      SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", ATTRS{name}=="aw86927-haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
      ACTION=="bind", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:010a:*", ATTR{power/control}="on"
    '';
  };

  environment = {
    etc = {
      "inputplumber/devices.d/40-retroid_duolite.yaml".source =
        "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/devices/40-retroid_duolite.yaml";
      "inputplumber/capability_maps.d/retroid_duolite.yaml".source =
        "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/capability_maps/retroid_duolite.yaml";
      "wireplumber/wireplumber.conf.d/90-sm6115-s16le.conf".source =
        "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/wireplumber/wireplumber.conf.d/90-sm6115-s16le.conf";
      "wireplumber/wireplumber.conf.d/91-suspend-on-idle.conf".source =
        "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/wireplumber/wireplumber.conf.d/91-suspend-on-idle.conf";
      "systemd/system-sleep/sm6125-bt".source = pkgs.writeShellScript "sm6125-bt" ''
        BT_UART_WAKEUP=/sys/devices/platform/soc@0/4ac0000.geniqup/4a8c000.serial/power/wakeup

        bt_uart_wakeup() {
          [ -e "''${BT_UART_WAKEUP}" ] && echo "''${1}" > "''${BT_UART_WAKEUP}"
        }

        case "$1" in
          pre)
            bt_uart_wakeup disabled
            ;;
          post)
            bt_uart_wakeup enabled
            ;;
        esac
      '';
    };

    pathsToLink = [
      "/share/alsa/ucm2"
      "/share/inputplumber"
    ];

    systemPackages = [
      pkgs.alsa-ucm-conf
      sm6125AlsaUcm
    ];
  };
}
