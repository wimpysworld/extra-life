{
  lib,
  pkgs,
  ...
}:
let
  rk3588CompositeProfile = pkgs.writeText "50-rk3588-handheld.yaml" ''
    version: 1
    kind: CompositeDevice
    name: RK3588 Handheld
    single_source: false
    matches: []
    source_devices:
      - group: gamepad
        evdev:
          name: GameForce ACE Gamepad
          handler: event*
        capability_map_id: rk3588_gamepad
      - group: gamepad
        evdev:
          name: Retro Lite CM5 Gamepad
          handler: event*
        capability_map_id: rk3588_gamepad
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
      - group: gamepad
        evdev:
          name: gpio-keys
          handler: event*
        capability_map_id: rk3588_gamepad
      - group: gamepad
        evdev:
          name: adc-keys
          handler: event*
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3588CapabilityMap = pkgs.writeText "rk3588_gamepad.yaml" ''
    version: 2
    kind: CapabilityMap
    name: RK3588 Handheld Gamepad
    id: rk3588_gamepad
    mapping:
      - name: DPad Up
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_DPAD_UP
              value_type: button
        target_event:
          gamepad:
            button: DPadUp
      - name: DPad Down
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_DPAD_DOWN
              value_type: button
        target_event:
          gamepad:
            button: DPadDown
      - name: DPad Left
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_DPAD_LEFT
              value_type: button
        target_event:
          gamepad:
            button: DPadLeft
      - name: DPad Right
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_DPAD_RIGHT
              value_type: button
        target_event:
          gamepad:
            button: DPadRight
      - name: Volume Up
        source_events:
          - evdev:
              event_type: KEY
              event_code: KEY_VOLUMEUP
              value_type: button
        target_event:
          keyboard: KEY_VOLUMEUP
      - name: Volume Down
        source_events:
          - evdev:
              event_type: KEY
              event_code: KEY_VOLUMEDOWN
              value_type: button
        target_event:
          keyboard: KEY_VOLUMEDOWN
  '';

  rk3588AlsaUcm = pkgs.runCommand "rk3588-alsa-ucm" { } ''
    mkdir -p "$out/share/alsa/ucm2/Rockchip" "$out/share/alsa/ucm2/conf.d/simple-card"
    cp -a "${pkgs.rocknix-rk3588}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/Rockchip/rockchip,es8388-codec" "$out/share/alsa/ucm2/Rockchip/"
    cp -a "${pkgs.rocknix-rk3588}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2/conf.d/simple-card/rockchip,es8388-codec.conf" "$out/share/alsa/ucm2/conf.d/simple-card/"
  '';
in
{
  extraLife.variantId = lib.mkDefault "rk3588";

  hardware.deviceTree.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_rk3588;

    kernelParams = [
      "console=ttyS2,1500000"
      "console=tty0"
      "cma=256M"
    ];

    initrd.availableKernelModules = [
      "mmc_block"
      "dw_mmc"
      "dw_mmc_pltfm"
      "dw_mmc_rockchip"
      "sdhci"
      "sdhci_pltfm"
      "sdhci_of_dwcmshc"
      "nvme"
      "pcie_rockchip_host"
      "rk8xx_core"
      "rk8xx_spi"
      "rk808_regulator"
      "rk860x_regulator"
      "phy_rockchip_samsung_hdptx"
      "phy_rockchip_naneng_combophy"
      "phy_rockchip_usbdp"
      "phy_rockchip_inno_usb2"
      "rockchipdrm"
      "panthor"
      "pwm_bl"
      "usbhid"
    ];

    kernelModules = [
      "panthor"
      "rockchipdrm"
      "dw_hdmi_qp_rockchip"
      "dw_dp"
      "phy_rockchip_samsung_hdptx"
      "phy_rockchip_naneng_combophy"
      "phy_rockchip_usbdp"
      "rockchip_saradc"
      "ti_ads1015"
      "adc_joystick"
      "adc_keys"
      "gpio_keys"
      "pwm_vibra"
      "pwm_gpio"
      "pwm_fan"
      "goodix_ts"
      "cw2015_battery"
      "max17042_battery"
      "bq257xx_charger"
      "gpio_charger"
      "fusb302"
      "rtc_hym8563"
      "snd_soc_rockchip_i2s_tdm"
      "snd_soc_es8328_i2c"
      "snd_soc_wm8960"
      "snd_soc_hdmi_codec"
      "snd_soc_simple_card"
      "snd_soc_simple_amplifier"
      "brcmfmac"
      "hci_uart"
      "btbcm"
    ];
  };

  services.inputplumber.enable = true;

  environment = {
    etc = {
      "inputplumber/devices.d/50-rk3588-handheld.yaml".source = rk3588CompositeProfile;
      "inputplumber/capability_maps.d/rk3588_gamepad.yaml".source = rk3588CapabilityMap;
    };

    pathsToLink = [
      "/share/alsa/ucm2"
      "/share/inputplumber"
    ];

    systemPackages = [
      pkgs.alsa-ucm-conf
      rk3588AlsaUcm
    ];
  };
}
