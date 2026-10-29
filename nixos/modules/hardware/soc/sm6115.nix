{
  lib,
  pkgs,
  ...
}:
let
  rocknixSm6115 = pkgs.rocknix-sm6115;

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

    kernelModules = [
      "ath10k_snoc"
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
      "snd_soc_qdsp6"
      "snd_soc_lpass_va_macro"
      "snd_soc_lpass_rx_macro"
      "snd_soc_lpass_tx_macro"
    ];
  };

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
