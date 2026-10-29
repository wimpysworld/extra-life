{
  lib,
  pkgs,
  ...
}:
let
  rk3566CompositeProfile = pkgs.writeText "50-rk3566-handheld.yaml" ''
    version: 1
    kind: CompositeDevice
    name: RK3566 Handheld
    single_source: false
    matches: []
    source_devices:
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
      - group: gamepad
        evdev:
          name: gpio-keys-control
          handler: event*
        capability_map_id: rk3566_gpio_keys
      - group: gamepad
        evdev:
          name: adc-keys
          handler: event*
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3566CapabilityMap = pkgs.writeText "rk3566_gpio_keys.yaml" ''
    version: 2
    kind: CapabilityMap
    name: RK3566 GPIO Keys D-Pad
    id: rk3566_gpio_keys
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
  '';
in
{
  extraLife.variantId = lib.mkDefault "rk3566";

  hardware.deviceTree.enable = true;

  boot = {
    initrd.availableKernelModules = [
      "mmc_block"
      "dw_mmc"
      "dw_mmc_pltfm"
      "dw_mmc_rockchip"
      "sdhci"
      "sdhci_pltfm"
      "sdhci_of_dwcmshc"
      "rk808"
      "rk808_regulator"
      "phy_rockchip_inno_dsidphy"
      "rockchipdrm"
      "panfrost"
      "panel_newvision_nv3051d"
      "panel_sitronix_st7703"
      "pwm_bl"
      "usbhid"
    ];

    kernelModules = [
      "panfrost"
      "rockchipdrm"
      "analogix_dp"
      "dw_hdmi_qp_rockchip"
      "phy_rockchip_inno_dsidphy"
      "panel_newvision_nv3051d"
      "panel_sitronix_st7703"
      "pwm_bl"
      "rockchip_saradc"
      "industrialio_mux"
      "mux_gpio"
      "adc_joystick"
      "adc_keys"
      "gpio_keys"
      "snd_soc_rk817"
      "snd_soc_rockchip_i2s_tdm"
      "snd_soc_simple_card"
      "snd_soc_simple_amplifier"
      "rk817_charger"
      "rtw88_8821cs"
      "hci_uart"
    ];
  };

  services.inputplumber.enable = true;

  environment.etc = {
    "inputplumber/devices.d/50-rk3566-handheld.yaml".source = rk3566CompositeProfile;
    "inputplumber/capability_maps.d/rk3566_gpio_keys.yaml".source = rk3566CapabilityMap;
  };

  environment.pathsToLink = [
    "/share/alsa/ucm2"
    "/share/inputplumber"
  ];

  environment.systemPackages = [
    pkgs.alsa-ucm-conf
  ];
}
