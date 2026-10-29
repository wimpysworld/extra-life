{
  config,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;

  caseConfigSnippet =
    {
      none = "";
      retroflag = ''
        enable_uart=1
        dtoverlay=gpio-poweroff,gpiopin=4,active_low=1,input=1
        dtoverlay=gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up
      '';
      gpi-case = ''
        dtoverlay=dpi24
        overscan_left=0
        overscan_right=0
        overscan_top=0
        overscan_bottom=0
        framebuffer_width=320
        framebuffer_height=240
        enable_dpi_lcd=1
        display_default_lcd=1
        dpi_group=2
        dpi_mode=87
        dpi_output_format=0x6016
        hdmi_timings=320 0 28 18 28 240 0 2 4 10 0 0 0 60 0 6400000 1
        dtoverlay=pwm-audio-pi-zero
        dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
        dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up
      '';
      gpi-case-2 = ''
        dtoverlay=dpi24
        overscan_left=0
        overscan_right=0
        overscan_top=0
        overscan_bottom=0
        framebuffer_width=640
        framebuffer_height=480
        enable_dpi_lcd=1
        display_default_lcd=1
        dpi_group=2
        dpi_mode=87
        dpi_output_format=0x00016
        dpi_timings=640 0 41 40 60 480 0 18 9 18 0 0 0 60 0 24000000 1
        dtoverlay=audremap,pins_18_19
        dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
        dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up
      '';
      gpi-case-2w = ''
        dtoverlay=dpi24
        overscan_left=0
        overscan_right=0
        overscan_top=0
        overscan_bottom=0
        framebuffer_width=640
        framebuffer_height=480
        enable_dpi_lcd=1
        display_default_lcd=1
        dpi_group=2
        dpi_mode=87
        dpi_output_format=0x00016
        dpi_timings=640 0 41 40 60 480 0 18 9 18 0 0 0 60 0 24000000 1
        dtoverlay=pwm-audio-pi-zero
        dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
        dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up
      '';
      deskpi-pro = ''
        dtoverlay=dwc2,dr_mode=host
        enable_uart=1
      '';
      argon-one = ''
        dtparam=i2c_arm=on
        enable_uart=1
        dtoverlay=gpio-shutdown,gpio_pin=4,active_low=0,gpio_pull=down
      '';
    }
    .${config.extraLife.case or "none"};

  configTxt = pkgs.writeText "config.txt" (
    ''
      arm_64bit=1
      kernel=KERNEL
      initramfs INITRD followkernel
      disable_overscan=1
      dtparam=audio=on
      dtparam=i2c_arm=on

      [pi02]
      dtoverlay=vc4-kms-v3d
      gpu_mem=64

      [pi3]
      dtoverlay=vc4-kms-v3d
      gpu_mem=64

      [pi4]
      dtoverlay=vc4-kms-v3d-pi4
      max_framebuffers=2
      arm_boost=1

      [cm4]
      otg_mode=1

      [pi5]
      dtoverlay=vc4-kms-v3d-pi5
      max_framebuffers=2

      [all]
    ''
    + caseConfigSnippet
    + ''
      include extralife-case.txt
    ''
  );

  extralifeCaseTxt = pkgs.writeText "extralife-case.txt" ''
    # Extra Life Raspberry Pi Retro Case Configuration
    # Uncomment the section matching your enclosure to enable safe shutdown,
    # DPI LCD timings, audio routing, or fan control without rebuilding.
    # For DeskPi Pro or Argon ONE fan control, also write "deskpi-pro" or
    # "argon-one" into /boot/case.txt.

    # --- RetroFlag NESPi / SUPERPi / MegaPi / PiStation ---
    # enable_uart=1
    # dtoverlay=gpio-poweroff,gpiopin=4,active_low=1,input=1
    # dtoverlay=gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up

    # --- RetroFlag GPi Case v1 (Zero 2 W) ---
    # dtoverlay=dpi24
    # overscan_left=0
    # overscan_right=0
    # overscan_top=0
    # overscan_bottom=0
    # framebuffer_width=320
    # framebuffer_height=240
    # enable_dpi_lcd=1
    # display_default_lcd=1
    # dpi_group=2
    # dpi_mode=87
    # dpi_output_format=0x6016
    # hdmi_timings=320 0 28 18 28 240 0 2 4 10 0 0 0 60 0 6400000 1
    # dtoverlay=pwm-audio-pi-zero
    # dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
    # dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up

    # --- RetroFlag GPi Case 2 (CM4) ---
    # dtoverlay=dpi24
    # overscan_left=0
    # overscan_right=0
    # overscan_top=0
    # overscan_bottom=0
    # framebuffer_width=640
    # framebuffer_height=480
    # enable_dpi_lcd=1
    # display_default_lcd=1
    # dpi_group=2
    # dpi_mode=87
    # dpi_output_format=0x00016
    # dpi_timings=640 0 41 40 60 480 0 18 9 18 0 0 0 60 0 24000000 1
    # dtoverlay=audremap,pins_18_19
    # dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
    # dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up

    # --- RetroFlag GPi Case 2W (Zero 2 W) ---
    # dtoverlay=dpi24
    # overscan_left=0
    # overscan_right=0
    # overscan_top=0
    # overscan_bottom=0
    # framebuffer_width=640
    # framebuffer_height=480
    # enable_dpi_lcd=1
    # display_default_lcd=1
    # dpi_group=2
    # dpi_mode=87
    # dpi_output_format=0x00016
    # dpi_timings=640 0 41 40 60 480 0 18 9 18 0 0 0 60 0 24000000 1
    # dtoverlay=pwm-audio-pi-zero
    # dtoverlay=gpio-poweroff,gpiopin=26,active_low=1,input=1
    # dtoverlay=gpio-shutdown,gpio_pin=27,active_low=1,gpio_pull=up

    # --- DeskPi Pro v1 / v2 ---
    # dtoverlay=dwc2,dr_mode=host
    # enable_uart=1

    # --- Argon ONE v2 / v3 ---
    # dtparam=i2c_arm=on
    # enable_uart=1
    # dtoverlay=gpio-shutdown,gpio_pin=4,active_low=0,gpio_pull=down
  '';

  cmdlineTxt = pkgs.writeText "cmdline.txt" ''
    init=/nix/store/current-system/init ${toString config.boot.kernelParams}
  '';

  rpiBootFiles = pkgs.runCommand "extra-life-rpi-boot" { } ''
    mkdir -p "$out/overlays"
    cp -f "${pkgs.raspberrypifw}"/share/raspberrypi/boot/bootcode.bin "$out/"
    cp -f "${pkgs.raspberrypifw}"/share/raspberrypi/boot/start*.elf "$out/"
    cp -f "${pkgs.raspberrypifw}"/share/raspberrypi/boot/fixup*.dat "$out/"

    for dtb in "${pkgs.raspberrypifw}"/share/raspberrypi/boot/bcm27*.dtb; do
      if [ -f "$dtb" ]; then
        cp -f "$dtb" "$out/"
      fi
    done

    if [ -d "${config.hardware.deviceTree.package}/broadcom" ]; then
      for dtb in "${config.hardware.deviceTree.package}"/broadcom/*.dtb; do
        if [ -f "$dtb" ]; then
          cp -f "$dtb" "$out/"
        fi
      done
    fi

    if [ -d "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays" ]; then
      cp -rf --no-preserve=mode "${pkgs.raspberrypifw}"/share/raspberrypi/boot/overlays/* "$out/overlays/"
    fi

    if [ -d "${config.hardware.deviceTree.package}/overlays" ]; then
      cp -rf --no-preserve=mode "${config.hardware.deviceTree.package}"/overlays/* "$out/overlays/"
    fi

    cp -f "${configTxt}" "$out/config.txt"
    cp -f "${extralifeCaseTxt}" "$out/extralife-case.txt"
    cp -f "${cmdlineTxt}" "$out/cmdline.txt"
  '';
in
{
  imports = [
    ./disk-base.nix
  ];

  image.repart.partitions."10-boot".contents = {
    "/".source = rpiBootFiles;
    "/KERNEL".source = "${toplevel}/kernel";
    "/INITRD".source = "${toplevel}/initrd";
    "/SYSTEM".source = config.system.build.systemSquashfs;
  };

  system.build.diskImage = config.system.build.repartImage.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
      config.extraLife.buildHostPkgs.gptfdisk
    ];
    postBuild = (oldAttrs.postBuild or "") + ''
      sgdisk -h 1 "${config.image.baseName}.raw"
    '';
  });
}
