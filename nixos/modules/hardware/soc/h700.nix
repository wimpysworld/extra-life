{
  lib,
  pkgs,
  ...
}:
let
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

  environment.pathsToLink = [
    "/share/alsa/ucm2"
  ];

  environment.systemPackages = [
    pkgs.alsa-ucm-conf
    h700AlsaUcm
  ];
}
