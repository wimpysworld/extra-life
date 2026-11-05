{
  lib,
  pkgs,
  ...
}:
let
  mkRk3566CapabilityMap =
    {
      fileName,
      name,
      id,
      invertX ? false,
      invertY ? false,
    }:
    pkgs.writeText fileName ''
      version: 2
      kind: CapabilityMap
      name: ${name}
      id: ${id}
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
        - name: South Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_SOUTH
                value_type: button
          target_event:
            gamepad:
              button: South
        - name: East Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_EAST
                value_type: button
          target_event:
            gamepad:
              button: East
        - name: North Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_NORTH
                value_type: button
          target_event:
            gamepad:
              button: North
        - name: West Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_WEST
                value_type: button
          target_event:
            gamepad:
              button: West
        - name: Left Bumper
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_TL
                value_type: button
          target_event:
            gamepad:
              button: LeftBumper
        - name: Right Bumper
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_TR
                value_type: button
          target_event:
            gamepad:
              button: RightBumper
        - name: Left Trigger
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_TL2
                value_type: trigger
          target_event:
            gamepad:
              trigger:
                name: LeftTrigger
        - name: Right Trigger
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_TR2
                value_type: trigger
          target_event:
            gamepad:
              trigger:
                name: RightTrigger
        - name: Select Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_SELECT
                value_type: button
          target_event:
            gamepad:
              button: Select
        - name: Start Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_START
                value_type: button
          target_event:
            gamepad:
              button: Start
        - name: Guide Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_MODE
                value_type: button
          target_event:
            gamepad:
              button: Guide
        - name: Home Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_BACK
                value_type: button
          target_event:
            gamepad:
              button: Guide
        - name: Guide Chord
          mapping_type:
            evdev: chord
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_SELECT
                value_type: button
            - evdev:
                event_type: KEY
                event_code: BTN_START
                value_type: button
          target_event:
            gamepad:
              button: Guide
        - name: Left Stick Click
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_THUMBL
                value_type: button
          target_event:
            gamepad:
              button: LeftStick
        - name: Right Stick Click
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_THUMBR
                value_type: button
          target_event:
            gamepad:
              button: RightStick
        - name: C Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_C
                value_type: button
          target_event:
            gamepad:
              button: RightStick
        - name: Z Button
          source_events:
            - evdev:
                event_type: KEY
                event_code: BTN_Z
                value_type: button
          target_event:
            gamepad:
              button: LeftStick
        - name: Left Stick
          source_events:
            - evdev:
                event_type: ABS
                event_code: ABS_X
                value_type: joystick_x
                invert: ${lib.boolToString invertX}
            - evdev:
                event_type: ABS
                event_code: ABS_Y
                value_type: joystick_y
                invert: ${lib.boolToString invertY}
          target_event:
            gamepad:
              axis:
                name: LeftStick
        - name: Right Stick
          source_events:
            - evdev:
                event_type: ABS
                event_code: ABS_RX
                value_type: joystick_x
                invert: ${lib.boolToString invertX}
            - evdev:
                event_type: ABS
                event_code: ABS_RY
                value_type: joystick_y
                invert: ${lib.boolToString invertY}
          target_event:
            gamepad:
              axis:
                name: RightStick
    '';

  rk3566CompositeProfile = pkgs.writeText "50-rk3566-handheld.yaml" ''
    version: 1
    kind: CompositeDevice
    name: RK3566 Handheld
    single_source: false
    matches:
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG353M
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG353P
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG353PS
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG353V
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG353VS
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG503
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG ARC-D
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Anbernic RG ARC-S
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy RGB10MAX3
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy RGB20 Pro
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy RGB20SX
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy RGB30
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy RK2023
    source_devices:
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
        capability_map_id: rk3566_gpio_keys
      - group: gamepad
        evdev:
          name: gpio-keys-control
          handler: event*
        capability_map_id: rk3566_gpio_keys
      - group: gamepad
        evdev:
          name: adc-keys
          handler: event*
        capability_map_id: rk3566_gpio_keys
      - group: gamepad
        evdev:
          name: adc-keys-home
          handler: event*
        capability_map_id: rk3566_gpio_keys
      - group: gamepad
        evdev:
          name: pwm-vibrator
          handler: event*
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3566PowkiddyX35sProfile = pkgs.writeText "40-powkiddy-x35s.yaml" ''
    version: 1
    kind: CompositeDevice
    name: Powkiddy X35S
    single_source: false
    matches:
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy x35s
    source_devices:
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
        capability_map_id: rk3566_powkiddy_x35s
      - group: gamepad
        evdev:
          name: gpio-keys-control
          handler: event*
        capability_map_id: rk3566_powkiddy_x35s
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3566PowkiddyX55Profile = pkgs.writeText "40-powkiddy-x55.yaml" ''
    version: 1
    kind: CompositeDevice
    name: Powkiddy X55
    single_source: false
    matches:
      - udev:
          sys_path: /sys/firmware/devicetree/base
          attributes:
            - name: model
              value: Powkiddy x55
    source_devices:
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
        capability_map_id: rk3566_powkiddy_x55
      - group: gamepad
        evdev:
          name: gpio-keys-control
          handler: event*
        capability_map_id: rk3566_powkiddy_x55
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3566CapabilityMap = mkRk3566CapabilityMap {
    fileName = "rk3566_gpio_keys.yaml";
    name = "RK3566 Gamepad";
    id = "rk3566_gpio_keys";
    invertX = false;
    invertY = true;
  };

  rk3566PowkiddyX35sCapabilityMap = mkRk3566CapabilityMap {
    fileName = "rk3566_powkiddy_x35s.yaml";
    name = "Powkiddy X35S Gamepad";
    id = "rk3566_powkiddy_x35s";
    invertX = true;
    invertY = false;
  };

  rk3566PowkiddyX55CapabilityMap = mkRk3566CapabilityMap {
    fileName = "rk3566_powkiddy_x55.yaml";
    name = "Powkiddy X55 Gamepad";
    id = "rk3566_powkiddy_x55";
    invertX = false;
    invertY = false;
  };

  rk3566BtFirmware =
    pkgs.runCommand "rk3566-bt-firmware"
      {
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/rtl_bt"
        cp -a "${pkgs.rocknix-rk3566}/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/rtl_bt/rtl8723ds_"*.bin "$out/lib/firmware/rtl_bt/"
      '';

  rk3566AlsaUcm = lib.hiPrio (
    pkgs.runCommand "rk3566-alsa-ucm-conf" { } ''
      mkdir -p "$out/share/alsa/ucm2/Rockchip/rk817-sound"
      mkdir -p "$out/share/alsa/ucm2/conf.d/simple-card"
      cp "${pkgs.alsa-ucm-conf}/share/alsa/ucm2/Rockchip/rk817-sound/rk817-sound.conf" \
        "$out/share/alsa/ucm2/Rockchip/rk817-sound/rk817-sound.conf"
      cp "${pkgs.alsa-ucm-conf}/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" \
        "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf"
      chmod u+w "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf"
      patch -p2 -d "$out/share/alsa/ucm2" < "${pkgs.rocknix-rk3566}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326/0001_fix_speaker_when_booting_with_headphones.patch"
      sed 's/^Define\.pbk_mux "SPK"$/Define.pbk_mux "HP"/' \
        "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" \
        > "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi-ext.conf"
      cat > "$out/share/alsa/ucm2/conf.d/simple-card/rk817_ext.conf" << 'EOF'
      Syntax 4

      Define.pbk_mux "HP"

      SectionUseCase."HiFi" {
      	File "/Rockchip/rk817-sound/HiFi-ext.conf"
      	Comment "Play HiFi quality music"
      }
      EOF
      for conf in rk817_int.conf rk817-sound.conf; do
        ln -sf ../../Rockchip/rk817-sound/rk817-sound.conf "$out/share/alsa/ucm2/conf.d/simple-card/$conf"
      done
    ''
  );
in
{
  extraLife.variantId = lib.mkDefault "rk3566";

  hardware = {
    deviceTree.enable = true;
    firmware = [
      rk3566BtFirmware
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_rk3566;

    kernelParams = [
      "console=ttyS2,1500000"
      "console=tty0"
      "cma=256M"
    ];

    extraModprobeConfig = "options rtw88_core disable_lps_deep=y";

    initrd.availableKernelModules = [
      "mmc_block"
      "dw_mmc"
      "dw_mmc_pltfm"
      "dw_mmc_rockchip"
      "sdhci"
      "sdhci_pltfm"
      "sdhci_of_dwcmshc"
      "rk8xx_core"
      "rk8xx_i2c"
      "rk808_regulator"
      "phy_rockchip_inno_dsidphy"
      "rockchipdrm"
      "panfrost"
      "panel_himax_hx8394"
      "panel_magnachip_d53e6ea8966"
      "panel_newvision_nv3051d"
      "panel_sitronix_st7701"
      "panel_sitronix_st7703"
      "pwm_bl"
      "spi_gpio"
      "usbhid"
    ];

    kernelModules = [
      "panfrost"
      "rockchipdrm"
      "analogix_dp"
      "dw_hdmi_qp_rockchip"
      "phy_rockchip_inno_dsidphy"
      "panel_himax_hx8394"
      "panel_magnachip_d53e6ea8966"
      "panel_newvision_nv3051d"
      "panel_sitronix_st7701"
      "panel_sitronix_st7703"
      "pwm_bl"
      "spi_gpio"
      "rockchip_saradc"
      "iio_mux"
      "mux_gpio"
      "adc_joystick"
      "adc_keys"
      "gpio_keys"
      "pwm_vibra"
      "goodix_ts"
      "snd_soc_rk817"
      "snd_soc_rockchip_i2s_tdm"
      "snd_soc_hdmi_codec"
      "snd_soc_simple_card"
      "snd_soc_simple_amplifier"
      "rk817_charger"
      "rtw88_8723ds"
      "rtw88_8821cs"
      "hci_uart"
      "btrtl"
    ];
  };

  services.inputplumber.enable = true;

  environment = {
    etc = {
      "inputplumber/devices.d/40-powkiddy-x35s.yaml".source = rk3566PowkiddyX35sProfile;
      "inputplumber/devices.d/40-powkiddy-x55.yaml".source = rk3566PowkiddyX55Profile;
      "inputplumber/devices.d/50-rk3566-handheld.yaml".source = rk3566CompositeProfile;
      "inputplumber/capability_maps.d/rk3566_gpio_keys.yaml".source = rk3566CapabilityMap;
      "inputplumber/capability_maps.d/rk3566_powkiddy_x35s.yaml".source = rk3566PowkiddyX35sCapabilityMap;
      "inputplumber/capability_maps.d/rk3566_powkiddy_x55.yaml".source = rk3566PowkiddyX55CapabilityMap;
    };

    pathsToLink = [
      "/share/alsa/ucm2"
      "/share/inputplumber"
    ];

    systemPackages = [
      pkgs.alsa-ucm-conf
      rk3566AlsaUcm
    ];
  };
}
