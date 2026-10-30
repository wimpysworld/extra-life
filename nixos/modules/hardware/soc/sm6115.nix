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

  sm6115Firmware =
    pkgs.runCommand "sm6115-firmware"
      {
        nativeBuildInputs = [ pkgs.zstd ];
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/qcom/qrb4210"
        cp -a "${rocknixExtraFirmware}/SM6115/." "$out/lib/firmware/"
        chmod -R u+w "$out/lib/firmware"
        for jsn in adspr.jsn adsps.jsn adspua.jsn; do
          zstd -d -f "${compressedLinuxFirmware}/lib/firmware/qcom/qrb4210/$jsn.zst" \
            -o "$out/lib/firmware/qcom/qrb4210/$jsn"
        done
      '';

  sm6115AlsaUcm = pkgs.runCommand "sm6115-alsa-ucm-conf" { } ''
    mkdir -p "$out/share/alsa/ucm2/Qualcomm/sm6115"
    mkdir -p "$out/share/alsa/ucm2/conf.d/sm4250"
    mkdir -p "$out/share/alsa/ucm2/conf.d/qrb4210-rb2-snd"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6115/MangmiAirX.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6115/MangmiAirX.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6115/HiFi-MangmiAirX.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6115/HiFi-MangmiAirX.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/MangmiAirX.conf \
      "$out/share/alsa/ucm2/conf.d/sm4250/MangmiAirX.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/MangmiAirX.conf \
      "$out/share/alsa/ucm2/conf.d/qrb4210-rb2-snd/MangmiAirX.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6115/MangmiAirY.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6115/MangmiAirY.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Qualcomm/sm6115/HiFi-MangmiAirY.conf \
      "$out/share/alsa/ucm2/Qualcomm/sm6115/HiFi-MangmiAirY.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/MangmiAirY.conf \
      "$out/share/alsa/ucm2/conf.d/sm4250/MangmiAirY.conf"
    cp ${rocknixSm6115}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/sm4250/MangmiAirY.conf \
      "$out/share/alsa/ucm2/conf.d/qrb4210-rb2-snd/MangmiAirY.conf"
  '';
in
{
  imports = [
    ./qcom-common.nix
  ];

  extraLife.variantId = lib.mkDefault "sm6115";

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
        "qcom/sm6115/mangmi/a610_zap.mbn"
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
        "panel_bm5460bb1"
        "panel_gh7005"
        "panel_td4310"
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
        "panel_bm5460bb1"
        "panel_gh7005"
        "panel_td4310"
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
      "panel_bm5460bb1"
      "panel_gh7005"
      "panel_td4310"
      "panel_retroid_duolite_bottom"
      "msm"
      "pwrseq_qcom_wcn"
      "ath10k_core"
      "ath10k_snoc"
      "fusb302"
      "pinctrl_sm6115_lpass_lpi"
      "hci_uart"
      "btqca"
      "mangmi"
      "pwm_vibra"
      "clk_pwm"
      "gpio_fan"
      "cw221x_battery"
      "himax_hx83112a"
      "himax_hx83112b"
      "hynitron_cstxxx"
      "snd_soc_aw88261"
      "snd_soc_es8326"
      "snd_soc_sm8250"
      "snd_soc_qcom_common"
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
    sm6115Firmware
  ];

  services.inputplumber.enable = true;

  environment.etc = {
    "inputplumber/devices.d/39-mangmi_airy.yaml".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/devices/39-mangmi_airy.yaml";
    "inputplumber/devices.d/40-mangmi_airx.yaml".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/devices/40-mangmi_airx.yaml";
    "inputplumber/capability_maps.d/mangmi_airx.yaml".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/capability_maps/mangmi_airx.yaml";
    "inputplumber/capability_maps.d/mangmi_airy.yaml".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/inputplumber/capability_maps/mangmi_airy.yaml";
    "wireplumber/wireplumber.conf.d/90-sm6115-s16le.conf".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/wireplumber/wireplumber.conf.d/90-sm6115-s16le.conf";
    "wireplumber/wireplumber.conf.d/91-suspend-on-idle.conf".source =
      "${rocknixSm6115}/projects/ROCKNIX/devices/SM6115/filesystem/usr/share/wireplumber/wireplumber.conf.d/91-suspend-on-idle.conf";
  };

  environment.pathsToLink = [
    "/share/alsa/ucm2"
    "/share/inputplumber"
  ];

  environment.systemPackages = [
    sm6115AlsaUcm
  ];
}
