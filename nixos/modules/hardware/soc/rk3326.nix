{
  lib,
  pkgs,
  ...
}:
let
  rk3326LudoToml = pkgs.writeText "ludo-rk3326.toml" ''
    video_fullscreen = true
    video_dark_mode = true
    video_theme = "Catppuccin"
    cores_dir = "/run/current-system/sw/lib/retroarch/cores"
    assets_dir = "/run/current-system/sw/share/ludo/assets"
    database_dir = "/run/current-system/sw/share/ludo/database"
    files_dir = "/storage/Retro/roms"
    playlists_dir = "/storage/Retro/playlists"
    savefiles_dir = "/storage/Retro/savefiles"
    savestates_dir = "/storage/Retro/savestates"
    screenshots_dir = "/storage/Retro/screenshots"
    system_dir = "/storage/Retro/system"
    thumbnail_dir = "/storage/Retro/thumbnails"

    [core_for_playlist]
    "Atari - 2600" = "stella2014_libretro"
    "Atari - 5200" = "atari800_libretro"
    "Atari - 7800" = "prosystem_libretro"
    "Atari - Jaguar" = "virtualjaguar_libretro"
    "Atari - Lynx" = "handy_libretro"
    "Atari - ST" = "hatari_libretro"
    "Bandai - WonderSwan" = "mednafen_wswan_libretro"
    "Bandai - WonderSwan Color" = "mednafen_wswan_libretro"
    "Cave Story" = "nxengine_libretro"
    "ChaiLove" = "chailove_libretro"
    "Coleco - ColecoVision" = "bluemsx_libretro"
    "FBNeo - Arcade Games" = "fbneo_libretro"
    "GCE - Vectrex" = "vecx_libretro"
    "Magnavox - Odyssey2" = "o2em_libretro"
    "Microsoft - MSX" = "bluemsx_libretro"
    "Microsoft - MSX2" = "bluemsx_libretro"
    "NEC - PC Engine - TurboGrafx 16" = "mednafen_pce_libretro"
    "NEC - PC Engine CD - TurboGrafx-CD" = "mednafen_pce_libretro"
    "NEC - PC Engine SuperGrafx" = "mednafen_pce_libretro"
    "NEC - PC-FX" = "mednafen_pcfx_libretro"
    "Nintendo - Family Computer Disk System" = "fceumm_libretro"
    "Nintendo - Game Boy" = "gambatte_libretro"
    "Nintendo - Game Boy Advance" = "mgba_libretro"
    "Nintendo - Game Boy Color" = "gambatte_libretro"
    "Nintendo - Nintendo 64" = "mupen64plus_next_libretro"
    "Nintendo - Nintendo DS" = "melonds_libretro"
    "Nintendo - Nintendo Entertainment System" = "fceumm_libretro"
    "Nintendo - Pokemon Mini" = "pokemini_libretro"
    "Nintendo - Satellaview" = "snes9x_libretro"
    "Nintendo - Sufami Turbo" = "snes9x_libretro"
    "Nintendo - Super Nintendo Entertainment System" = "snes9x_libretro"
    "Nintendo - Virtual Boy" = "mednafen_vb_libretro"
    "Philips - Videopac+" = "o2em_libretro"
    "Sega - 32X" = "picodrive_libretro"
    "Sega - Dreamcast" = "flycast_libretro"
    "Sega - Game Gear" = "genesis_plus_gx_libretro"
    "Sega - Master System - Mark III" = "genesis_plus_gx_libretro"
    "Sega - Mega Drive - Genesis" = "genesis_plus_gx_libretro"
    "Sega - Mega-CD - Sega CD" = "genesis_plus_gx_libretro"
    "Sega - PICO" = "picodrive_libretro"
    "Sega - SG-1000" = "genesis_plus_gx_libretro"
    "SNK - Neo Geo Pocket" = "mednafen_ngp_libretro"
    "SNK - Neo Geo Pocket Color" = "mednafen_ngp_libretro"
    "Sony - PlayStation" = "pcsx_rearmed_libretro"
    "Sony - PlayStation Portable" = "ppsspp_libretro"
    "Spectravideo - SVI-318 - SVI-328" = "bluemsx_libretro"
  '';

  rk3326CompositeProfile = pkgs.writeText "50-rk3326-handheld.yaml" ''
    version: 1
    kind: CompositeDevice
    name: RK3326 Handheld
    single_source: false
    matches: []
    source_devices:
      - group: gamepad
        evdev:
          name: odroidgo2_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: odroidgo2_v11_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: odroidgo3_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: r36s_Gamepad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: r33s_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: retrogame_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: retrogame_joypad_s1_f2
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: XU10 Gamepad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: XU Mini M Gamepad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: gkd_pixel2_joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: rocknix-joypad
          handler: event*
        capability_map_id: rk3326_gamepad
      - group: gamepad
        evdev:
          name: OpenSimHardware OSH PB Controller
          vendor_id: "1209"
          product_id: "3100"
          handler: event*
        capability_map_id: rg351_gamepad
    options:
      auto_manage: true
    target_devices:
      - xb360
  '';

  rk3326CapabilityMap = pkgs.writeText "rk3326_gamepad.yaml" ''
    version: 2
    kind: CapabilityMap
    name: RK3326 Gamepad
    id: rk3326_gamepad
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
      - name: Function 1 Select Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY1
              value_type: button
        target_event:
          gamepad:
            button: Select
      - name: Function 2 Left Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY2
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: LeftTrigger
      - name: Function 3 Guide Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY3
              value_type: button
        target_event:
          gamepad:
            button: Guide
      - name: Function 4 Guide Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY4
              value_type: button
        target_event:
          gamepad:
            button: Guide
      - name: Function 5 Right Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY5
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: RightTrigger
      - name: Function 6 Start Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TRIGGER_HAPPY6
              value_type: button
        target_event:
          gamepad:
            button: Start
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

  rg351CapabilityMap = pkgs.writeText "rg351_gamepad.yaml" ''
    version: 2
    kind: CapabilityMap
    name: Anbernic RG351 Gamepad
    id: rg351_gamepad
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
      - name: East Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_SOUTH
              value_type: button
        target_event:
          gamepad:
            button: East
      - name: South Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_EAST
              value_type: button
        target_event:
          gamepad:
            button: South
      - name: North Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_C
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
      - name: Left Bumper
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_WEST
              value_type: button
        target_event:
          gamepad:
            button: LeftBumper
      - name: Right Bumper
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_Z
              value_type: button
        target_event:
          gamepad:
            button: RightBumper
      - name: Left Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_SELECT
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: LeftTrigger
      - name: Right Trigger
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_START
              value_type: trigger
        target_event:
          gamepad:
            trigger:
              name: RightTrigger
      - name: Select Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TR
              value_type: button
        target_event:
          gamepad:
            button: Select
      - name: Start Button
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TL
              value_type: button
        target_event:
          gamepad:
            button: Start
      - name: Left Stick Click
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TL2
              value_type: button
        target_event:
          gamepad:
            button: LeftStick
      - name: Right Stick Click
        source_events:
          - evdev:
              event_type: KEY
              event_code: BTN_TR2
              value_type: button
        target_event:
          gamepad:
            button: RightStick
      - name: Left Stick
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_Z
              value_type: joystick_x
              invert: true
          - evdev:
              event_type: ABS
              event_code: ABS_RX
              value_type: joystick_y
              invert: true
        target_event:
          gamepad:
            axis:
              name: LeftStick
      - name: Right Stick
        source_events:
          - evdev:
              event_type: ABS
              event_code: ABS_RY
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

  esp8089FirmwareSrc = pkgs.fetchFromGitHub {
    owner = "armbian";
    repo = "firmware";
    rev = "490722a3c9181d6fee6ad75682aaba4afd9d4b24";
    sparseCheckout = [
      "eagle_fw_ate_config_v19.bin"
      "eagle_fw_first_init_v19.bin"
      "eagle_fw_second_init_v19.bin"
    ];
    hash = "sha256-FpCsvTq382lDowExnDLpLNGnTeZNg6lypRGuLb/YH4k=";
  };

  rk3326Firmware =
    pkgs.runCommand "rk3326-firmware"
      {
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out/lib/firmware/rtl_bt"
        cp -a "${esp8089FirmwareSrc}/eagle_fw_"*.bin "$out/lib/firmware/"
        cp -a "${pkgs.rocknix-rk3566}/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/rtl_bt/rtl8723ds_"*.bin "$out/lib/firmware/rtl_bt/"
      '';

  rk3326AlsaUcm = lib.hiPrio (
    pkgs.runCommand "rk3326-alsa-ucm-conf" { } ''
      mkdir -p "$out/share/alsa/ucm2/Rockchip/rk817-sound"
      mkdir -p "$out/share/alsa/ucm2/conf.d/simple-card"
      cp "${pkgs.alsa-ucm-conf}/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" \
        "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf"
      chmod u+w "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf"
      patch -p2 -d "$out/share/alsa/ucm2" < "${pkgs.rocknix-rk3326}/projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326/0001_fix_speaker_when_booting_with_headphones.patch"
      cat >> "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" << 'EOF'

      FixedBootSequence [
      	cset "name='Master Playback Volume' 255"
      ]
      EOF
      sed \
        -e 's/^Define\.pbk_mux "SPK"$/Define.pbk_mux "HP"/' \
        -e "s/cset \"name='Playback Mux' HP\"/cset \"name='Playback Mux' SPK\"/" \
        "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" \
        > "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi-inverted.conf"
      ln -sf /run/extra-life-rk817-HiFi.conf "$out/share/alsa/ucm2/Rockchip/rk817-sound/HiFi-active.conf"
      cat > "$out/share/alsa/ucm2/Rockchip/rk817-sound/rk817-sound.conf" << 'EOF'
      Syntax 4

      SectionUseCase."HiFi" {
      	File "/Rockchip/rk817-sound/HiFi-active.conf"
      	Comment "Play HiFi quality music"
      }
      EOF
      for conf in rk817_int.conf rk817_ext.conf rk817-sound.conf; do
        ln -sf ../../Rockchip/rk817-sound/rk817-sound.conf "$out/share/alsa/ucm2/conf.d/simple-card/$conf"
      done
    ''
  );
in
{
  extraLife.variantId = lib.mkDefault "rk3326";

  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      libretro-cores =
        final.runCommand "libretro-cores-rk3326"
          {
            passthru = prev.libretro-cores.passthru or { };
            inherit (prev.libretro-cores) meta;
          }
          ''
            mkdir -p "$out/lib/retroarch/cores"
            for so in "${prev.libretro-cores}/lib/retroarch/cores/"*.so; do
              case "$(basename "$so")" in
                citra_libretro.so | dolphin_libretro.so | mednafen_saturn_libretro.so)
                  continue
                  ;;
              esac
              cp -a "$so" "$out/lib/retroarch/cores/"
            done
          '';
    })
  ];

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
  };

  hardware = {
    deviceTree.enable = true;
    firmware = [
      rk3326Firmware
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_rk3326;

    kernelParams = [
      "console=ttyS2,1500000"
      "console=tty0"
      "cma=256M"
    ];

    initrd = {
      availableKernelModules = [
        "mmc_block"
        "dw_mmc"
        "dw_mmc_pltfm"
        "dw_mmc_rockchip"
        "rk8xx_core"
        "rk8xx_i2c"
        "rk808_regulator"
        "phy_rockchip_inno_dsidphy"
        "rockchipdrm"
        "panfrost"
        "panel_elida_kd35t133"
        "panel_newvision_nv3051d"
        "panel_sitronix_st7701"
        "panel_sitronix_st7703"
        "pwm_bl"
        "usbhid"
      ];
    };

    kernelModules = [
      "panfrost"
      "rockchipdrm"
      "phy_rockchip_inno_dsidphy"
      "panel_elida_kd35t133"
      "panel_newvision_nv3051d"
      "panel_sitronix_st7701"
      "panel_sitronix_st7703"
      "pwm_bl"
      "rockchip_saradc"
      "adc_joystick"
      "adc_keys"
      "gpio_keys"
      "gpio_keys_polled"
      "pwm_vibra"
      "snd_soc_rk817"
      "snd_soc_rockchip_i2s"
      "snd_soc_rockchip_i2s_tdm"
      "snd_soc_simple_card"
      "snd_soc_simple_amplifier"
      "rk817_charger"
      "esp8089"
      "mt7601u"
      "rtl8xxxu"
      "rtw88_8723ds"
      "rtw88_8723du"
      "rtw88_8821cs"
      "rtw88_8821cu"
      "hci_uart"
    ];
  };

  services.inputplumber.enable = true;

  services.udev.extraHwdb = ''
    evdev:name:*joypad*
     ID_INPUT_TABLET=1
     ID_INPUT_TABLET_PAD=1

    evdev:name:*Gamepad*
     ID_INPUT_TABLET=1
     ID_INPUT_TABLET_PAD=1
  '';

  systemd.tmpfiles.rules = [
    "L+ /run/extra-life-rk817-HiFi.conf - - - - ${rk3326AlsaUcm}/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf"
  ];

  systemd.services.extra-life-rk3326-audio = {
    description = "Apply RK3326 board-specific ALSA routing quirks";
    wantedBy = [ "multi-user.target" ];
    after = [
      "extra-life-board-detect.service"
      "sound.target"
    ];
    before = [
      "cage-tty1.service"
    ];
    wants = [ "extra-life-board-detect.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = [ "-/run/extra-life-board.env" ];
      ExecStart = pkgs.writeShellScript "extra-life-rk3326-audio" ''
        set -euo pipefail
        case "''${EXTRA_LIFE_BOARD:-}" in
          anbernic-rg351m | gameconsole-r33s | gameconsole-r36s | powkiddy-rgb20s | powkiddy-rgb10x | magicx-xu-mini-m)
            ln -sf "${rk3326AlsaUcm}/share/alsa/ucm2/Rockchip/rk817-sound/HiFi-inverted.conf" /run/extra-life-rk817-HiFi.conf
            ${pkgs.alsa-utils}/bin/amixer -c 0 sset 'Master' 100% || true
            ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Playback Mux' HP || true
            ;;
          *)
            ln -sf "${rk3326AlsaUcm}/share/alsa/ucm2/Rockchip/rk817-sound/HiFi.conf" /run/extra-life-rk817-HiFi.conf
            ${pkgs.alsa-utils}/bin/amixer -c 0 sset 'Master' 100% || true
            ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Playback Mux' SPK || true
            ;;
        esac
      '';
    };
  };

  environment = {
    etc = {
      "ludo.toml".source = lib.mkForce rk3326LudoToml;
      "inputplumber/devices.d/50-rk3326-handheld.yaml".source = rk3326CompositeProfile;
      "inputplumber/capability_maps.d/rk3326_gamepad.yaml".source = rk3326CapabilityMap;
      "inputplumber/capability_maps.d/rg351_gamepad.yaml".source = rg351CapabilityMap;
      "systemd/system-sleep/rk3326-sleep".source = pkgs.writeShellScript "rk3326-sleep" ''
        case "$1" in
          pre)
            for mod in esp8089 rtw88_8821cs dwc2; do
              if [ -d "/sys/module/$mod" ]; then
                echo "$mod" >> /run/extra-life-rk3326-sleep.modules
                ${pkgs.kmod}/bin/modprobe -r "$mod" || true
              fi
            done
            ;;
          post)
            if [ -f /run/extra-life-rk3326-sleep.modules ]; then
              while read -r mod; do
                [ -n "$mod" ] && ${pkgs.kmod}/bin/modprobe "$mod" || true
              done < /run/extra-life-rk3326-sleep.modules
              rm -f /run/extra-life-rk3326-sleep.modules
            fi
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
      rk3326AlsaUcm
    ];
  };
}
