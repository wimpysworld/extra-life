{
  lib,
  pkgs,
  ...
}:
let
  h700CompositeProfile = pkgs.writeText "50-h700-handheld.yaml" ''
    version: 1
    kind: CompositeDevice
    name: H700 Handheld
    single_source: false
    matches: []
    source_devices:
      - group: gamepad
        evdev:
          name: H700 Gamepad
          handler: event*
        capability_map_id: h700_gamepad
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  h700CapabilityMap = pkgs.writeText "h700_gamepad.yaml" ''
    version: 2
    kind: CapabilityMap
    name: H700 Gamepad
    id: h700_gamepad
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
  '';

  h700PanelFirmware =
    pkgs.runCommand "h700-panel-firmware"
      {
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/panels"
        cp -a "${pkgs.rocknix-h700}/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels/." "$out/lib/firmware/panels/"
      '';

  h700AlsaUcm = lib.hiPrio (
    pkgs.runCommand "h700-alsa-ucm-conf" { } ''
      mkdir -p "$out/share/alsa/ucm2/Allwinner/sun4i-h616"
      mkdir -p "$out/share/alsa/ucm2/conf.d/sun4i-codec"
      cat > "$out/share/alsa/ucm2/Allwinner/sun4i-h616/HiFi.conf" << 'EOF'
      SectionDevice."Speaker" {
      	Comment "Internal Speaker"

      	EnableSequence [
      		cset "name='DAC Playback Volume' 63"
      		cset "name='Speaker Switch' on"
      	]

      	Value {
      		PlaybackMixerElem "Line Out"
      		PlaybackPCM "hw:''${CardId},0"
      	}

      	DisableSequence [
      		cset "name='Speaker Switch' off"
      	]

      	ConflictingDevice [
      		"Headphones"
      	]
      }


      SectionDevice."Headphones" {
      	Comment "Headphones"

      	EnableSequence [
      		cset "name='DAC Playback Volume' 63"
      	]

      	Value {
      		PlaybackMixerElem "Line Out"
      		PlaybackPCM "hw:''${CardId},0"
      		JackControl "Headphone Jack"
      	}

      	ConflictingDevice [
      		"Speaker"
      	]
      }
      EOF
      cat > "$out/share/alsa/ucm2/conf.d/sun4i-codec/h616-audio-codec.conf" << 'EOF'
      # UCM for Allwinner H616 Codec

      Syntax 3

      SectionUseCase."HiFi" {
      	File "/Allwinner/sun4i-h616/HiFi.conf"
      	Comment "Play HiFi quality Music"
      }

      FixedBootSequence [
      	cset "name='DAC Playback Switch' on"
      ]
      EOF
    ''
  );
in
{
  extraLife.variantId = lib.mkDefault "h700";

  hardware = {
    deviceTree.enable = true;
    firmware = [
      h700PanelFirmware
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_h700;

    kernelParams = [
      "console=ttyS0,115200"
      "console=tty0"
    ];

    initrd = {
      extraFirmwarePaths = [
        "panels/anbernic,rg28xx-panel.panel"
        "panels/anbernic,rg34xx-panel.panel"
        "panels/anbernic,rg34xx-sp-panel.panel"
        "panels/anbernic,rg34xx-sp-v2-panel.panel"
        "panels/anbernic,rg35xx-plus-panel.panel"
        "panels/anbernic,rg35xx-plus-rev6-panel.panel"
        "panels/anbernic,rg35xx-sp-v2-panel.panel"
        "panels/anbernic,rg40xx-panel.panel"
        "panels/anbernic,rg40xx-v2-panel.panel"
        "panels/anbernic,rgcubexx-panel.panel"
        "rtw88/rtw8821c_fw.bin"
        "rtl_bt/rtl8821cs_config.bin"
        "rtl_bt/rtl8821cs_fw.bin"
      ];

      availableKernelModules = [
        "panfrost"
        "pwm_bl"
        "spi_gpio"
        "iio_mux"
        "mux_gpio"
        "snd_soc_sun4i_codec"
        "snd_soc_sun4i_i2s"
        "snd_soc_sun4i_spdif"
        "snd_soc_simple_card"
        "rtw88_8821cs"
        "hci_uart"
        "btrtl"
        "usbhid"
      ];
    };

    kernelModules = [
      "panfrost"
      "pwm_bl"
      "spi_gpio"
      "iio_mux"
      "mux_gpio"
      "snd_soc_sun4i_codec"
      "snd_soc_sun4i_i2s"
      "snd_soc_sun4i_spdif"
      "snd_soc_simple_card"
      "rtw88_8821cs"
      "hci_uart"
      "btrtl"
      "usbhid"
    ];
  };

  services.cage.environment.MESA_EXTENSION_OVERRIDE = "-GL_OES_copy_image -GL_EXT_copy_image -GL_NV_copy_image -GL_ARB_copy_image";

  services.inputplumber.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  services.udev = {
    extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="sdio", KERNELS=="mmc2:0001:1", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
    '';

    extraHwdb = ''
      evdev:name:*Gamepad*
       ID_INPUT_TABLET=1
       ID_INPUT_TABLET_PAD=1
    '';
  };

  environment.etc = {
    "inputplumber/devices.d/50-h700-handheld.yaml".source = h700CompositeProfile;
    "inputplumber/capability_maps.d/h700_gamepad.yaml".source = h700CapabilityMap;
  };

  environment.pathsToLink = [
    "/share/alsa/ucm2"
    "/share/inputplumber"
  ];

  environment.systemPackages = [
    pkgs.alsa-ucm-conf
    h700AlsaUcm
  ];
}
