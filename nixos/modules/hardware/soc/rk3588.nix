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
        capability_map_id: retro_lite_cm5_gamepad
      - group: gamepad
        evdev:
          name: adc-joystick
          handler: event*
        capability_map_id: rk3588_gamepad
      - group: gamepad
        evdev:
          name: gpio-keys
          handler: event*
        capability_map_id: rk3588_gamepad
      - group: gamepad
        evdev:
          name: adc-keys
          handler: event*
        capability_map_id: rk3588_gamepad
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
              event_type: ABS
              event_code: ABS_HAT2X
              value_type: trigger
        target_event:
          gamepad:
            axis:
              name: LeftTrigger
            trigger:
              name: LeftTrigger
      - name: Right Trigger
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_HAT2Y
              value_type: trigger
        target_event:
          gamepad:
            axis:
              name: RightTrigger
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
      - name: Home Key
        source_events:
          - evdev:
              event_type: KEY
              event_code: KEY_HOME
              value_type: button
        target_event:
          gamepad:
            button: Guide
      - name: Home Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_C
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
      - name: Left Stick
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_X
              value_type: joystick_x
          - evdev:
              event_type: ABS
              event_code: ABS_Y
              value_type: joystick_y
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
          - evdev:
              event_type: ABS
              event_code: ABS_RY
              value_type: joystick_y
        target_event:
          gamepad:
            axis:
              name: RightStick
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

  retroLiteCm5CapabilityMap = pkgs.writeText "retro_lite_cm5_gamepad.yaml" ''
    version: 2
    kind: CapabilityMap
    name: Retro Lite CM5 Gamepad
    id: retro_lite_cm5_gamepad
    mapping:
      - name: DPad Up
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_HAT0Y
              value_type: button
              axis_direction: negative
        target_event:
          gamepad:
            button: DPadUp
      - name: DPad Down
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_HAT0Y
              value_type: button
              axis_direction: positive
        target_event:
          gamepad:
            button: DPadDown
      - name: DPad Left
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_HAT0X
              value_type: button
              axis_direction: negative
        target_event:
          gamepad:
            button: DPadLeft
      - name: DPad Right
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_HAT0X
              value_type: button
              axis_direction: positive
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
      - name: South Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY1
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
      - name: East Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY2
              value_type: button
        target_event:
          gamepad:
            button: East
      - name: North Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_C
              value_type: button
        target_event:
          gamepad:
            button: North
      - name: North Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY3
              value_type: button
        target_event:
          gamepad:
            button: North
      - name: West Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_NORTH
              value_type: button
        target_event:
          gamepad:
            button: West
      - name: West Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY4
              value_type: button
        target_event:
          gamepad:
            button: West
      - name: Start Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_WEST
              value_type: button
        target_event:
          gamepad:
            button: Start
      - name: Start Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY5
              value_type: button
        target_event:
          gamepad:
            button: Start
      - name: Select Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_Z
              value_type: button
        target_event:
          gamepad:
            button: Select
      - name: Select Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY6
              value_type: button
        target_event:
          gamepad:
            button: Select
      - name: Left Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TL
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: LeftTrigger
      - name: Left Trigger Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY7
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: LeftTrigger
      - name: Right Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TR
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: RightTrigger
      - name: Right Trigger Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY8
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: RightTrigger
      - name: Right Bumper
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_SELECT
              value_type: button
        target_event:
          gamepad:
            button: RightBumper
      - name: Right Bumper Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY11
              value_type: button
        target_event:
          gamepad:
            button: RightBumper
      - name: Left Bumper
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_START
              value_type: button
        target_event:
          gamepad:
            button: LeftBumper
      - name: Left Bumper Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY12
              value_type: button
        target_event:
          gamepad:
            button: LeftBumper
      - name: Left Stick Click
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_MODE
              value_type: button
        target_event:
          gamepad:
            button: LeftStick
      - name: Left Stick Click Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY13
              value_type: button
        target_event:
          gamepad:
            button: LeftStick
      - name: Right Stick Click
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_THUMBL
              value_type: button
        target_event:
          gamepad:
            button: RightStick
      - name: Right Stick Click Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY14
              value_type: button
        target_event:
          gamepad:
            button: RightStick
      - name: Guide Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_THUMBR
              value_type: button
        target_event:
          gamepad:
            button: Guide
      - name: Guide Button Happy
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY15
              value_type: button
        target_event:
          gamepad:
            button: Guide
      - name: Left Stick
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_X
              value_type: joystick_x
          - evdev:
              event_type: ABS
              event_code: ABS_Y
              value_type: joystick_y
        target_event:
          gamepad:
            axis:
              name: LeftStick
      - name: Right Stick
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_Z
              value_type: joystick_x
          - evdev:
              event_type: ABS
              event_code: ABS_RZ
              value_type: joystick_y
        target_event:
          gamepad:
            axis:
              name: RightStick
  '';

  rk3588AlsaUcm = pkgs.runCommand "rk3588-alsa-ucm" { } ''
    mkdir -p \
      "$out/share/alsa/ucm2/Rockchip/rockchip,es8388-codec" \
      "$out/share/alsa/ucm2/Rockchip/rockchip,es8388" \
      "$out/share/alsa/ucm2/Rockchip/wm8960-soundcard" \
      "$out/share/alsa/ucm2/conf.d/simple-card"

    cat > "$out/share/alsa/ucm2/conf.d/simple-card/rockchip,es8388-codec.conf" << 'EOF'
    Syntax 4

    SectionUseCase."HiFi" {
    	File "../../Rockchip/rockchip,es8388-codec/HiFi.conf"
    	Comment "Play HiFi quality music"
    }
    EOF

    cat > "$out/share/alsa/ucm2/Rockchip/rockchip,es8388-codec/HiFi.conf" << 'EOF'
    Syntax 4

    BootSequence [
    	cset "name='Left Mixer Left DAC Playback Switch' on"
    	cset "name='Right Mixer Right DAC Playback Switch' on"
    	cset "name='PCM Playback Volume' 192"
    	cset "name='Output 1 Playback Volume' 27"
    	cset "name='Output 2 Playback Volume' 27"
    	cset "name='Speaker Switch' on"
    	cset "name='Headphones Switch' off"
    ]

    SectionDevice."Speaker" {
    	Comment "Internal Speakers"

    	EnableSequence [
    		cset "name='Speaker Switch' on"
    	]

    	DisableSequence [
    		cset "name='Speaker Switch' off"
    	]

    	Value {
    		PlaybackPriority 100
    		PlaybackPCM "hw:''${CardId}"
    	}
    }

    SectionDevice."Headphones" {
    	Comment "Headphones"

    	EnableSequence [
    		cset "name='Headphones Switch' on"
    	]

    	DisableSequence [
    		cset "name='Headphones Switch' off"
    	]

    	ConflictingDevice [
    		"Speaker"
    	]

    	Value {
    		PlaybackPriority 200
    		PlaybackPCM "hw:''${CardId}"
    		JackControl "Headphones Jack"
    	}
    }
    EOF

    cat > "$out/share/alsa/ucm2/conf.d/simple-card/rockchip,es8388.conf" << 'EOF'
    Syntax 4

    SectionUseCase."HiFi" {
    	File "../../Rockchip/rockchip,es8388/HiFi.conf"
    	Comment "Play HiFi quality music"
    }
    EOF

    cat > "$out/share/alsa/ucm2/Rockchip/rockchip,es8388/HiFi.conf" << 'EOF'
    Syntax 4

    BootSequence [
    	cset "name='Left Mixer Left DAC Playback Switch' on"
    	cset "name='Right Mixer Right DAC Playback Switch' on"
    	cset "name='PCM Playback Volume' 192"
    	cset "name='Output 1 Playback Volume' 27"
    	cset "name='Output 2 Playback Volume' 27"
    ]

    SectionDevice."Headphones" {
    	Comment "Headphones"

    	Value {
    		PlaybackPriority 200
    		PlaybackPCM "hw:''${CardId}"
    	}
    }
    EOF

    cat > "$out/share/alsa/ucm2/conf.d/simple-card/wm8960-soundcard.conf" << 'EOF'
    Syntax 4

    SectionUseCase."HiFi" {
    	File "../../Rockchip/wm8960-soundcard/HiFi.conf"
    	Comment "Play HiFi quality music"
    }
    EOF

    cat > "$out/share/alsa/ucm2/Rockchip/wm8960-soundcard/HiFi.conf" << 'EOF'
    Syntax 4

    BootSequence [
    	cset "name='Playback Volume' 243,243"
    	cset "name='Speaker Playback Volume' 127,127"
    	cset "name='Headphone Playback Volume' 121,121"
    	cset "name='Speaker DC Volume' 5"
    	cset "name='Speaker AC Volume' 5"
    	cset "name='Left Output Mixer PCM Playback Switch' on"
    	cset "name='Right Output Mixer PCM Playback Switch' on"
    	cset "name='DAC Polarity' 'Left Inverted'"
    ]

    SectionDevice."Speaker" {
    	Comment "Internal Speakers"

    	Value {
    		PlaybackPriority 100
    		PlaybackPCM "hw:''${CardId}"
    		PlaybackMixerElem "Speaker"
    	}
    }

    SectionDevice."Headphones" {
    	Comment "Headphones"

    	ConflictingDevice [
    		"Speaker"
    	]

    	Value {
    		PlaybackPriority 200
    		PlaybackPCM "hw:''${CardId}"
    		PlaybackMixerElem "Headphone"
    		JackControl "Headphone Jack"
    	}
    }
    EOF
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

    initrd = {
      extraFirmwarePaths = [
        "arm/mali/arch10.8/mali_csffw.bin"
      ];

      availableKernelModules = [
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
        "panel_himax_hx8394"
        "panel_raydium_rm67191"
        "pwm_bl"
        "usbhid"
      ];
    };

    kernelModules = [
      "panthor"
      "rockchipdrm"
      "panel_himax_hx8394"
      "panel_raydium_rm67191"
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
      "inv_mpu6050_i2c"
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
      "iwlwifi"
      "iwlmvm"
      "hci_uart"
      "btbcm"
      "btusb"
      "btintel"
      "btrtl"
    ];
  };

  services.inputplumber.enable = true;

  environment = {
    etc = {
      "inputplumber/devices.d/50-rk3588-handheld.yaml".source = rk3588CompositeProfile;
      "inputplumber/capability_maps.d/rk3588_gamepad.yaml".source = rk3588CapabilityMap;
      "inputplumber/capability_maps.d/retro_lite_cm5_gamepad.yaml".source = retroLiteCm5CapabilityMap;
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
