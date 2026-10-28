{
  config,
  lib,
  pkgs,
  ...
}:
let
  ludoLauncher = pkgs.writeShellScript "extra-life-ludo" ''
    export HOME="/storage"
    export XDG_CONFIG_HOME="/storage/.config"
    export XDG_DATA_HOME="/storage/.local/share"
    export XDG_CACHE_HOME="/storage/.cache"
    export SDL_VIDEODRIVER="wayland"
    export EXTRA_LIFE_UPDATE_URL="https://extralife-ota.wimpys.world/releases.json"
    export EXTRA_LIFE_DEVICE="${config.extraLife.variantId}"
    export VERSION="${config.extraLife.versionId}"
    exec ${pkgs.ludo}/bin/ludo -ludos
  '';

  playstationCore =
    if pkgs.stdenv.hostPlatform.isx86_64 then "swanstation_libretro" else "pcsx_rearmed_libretro";

  ludoToml = pkgs.writeText "ludo.toml" ''
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
    "Nintendo - GameCube" = "dolphin_libretro"
    "Nintendo - Nintendo 3DS" = "citra_libretro"
    "Nintendo - Nintendo 64" = "mupen64plus_next_libretro"
    "Nintendo - Nintendo DS" = "melonds_libretro"
    "Nintendo - Nintendo Entertainment System" = "fceumm_libretro"
    "Nintendo - Pokemon Mini" = "pokemini_libretro"
    "Nintendo - Satellaview" = "snes9x_libretro"
    "Nintendo - Sufami Turbo" = "snes9x_libretro"
    "Nintendo - Super Nintendo Entertainment System" = "snes9x_libretro"
    "Nintendo - Virtual Boy" = "mednafen_vb_libretro"
    "Nintendo - Wii" = "dolphin_libretro"
    "Philips - Videopac+" = "o2em_libretro"
    "Sega - 32X" = "picodrive_libretro"
    "Sega - Dreamcast" = "flycast_libretro"
    "Sega - Game Gear" = "genesis_plus_gx_libretro"
    "Sega - Master System - Mark III" = "genesis_plus_gx_libretro"
    "Sega - Mega Drive - Genesis" = "genesis_plus_gx_libretro"
    "Sega - Mega-CD - Sega CD" = "genesis_plus_gx_libretro"
    "Sega - PICO" = "picodrive_libretro"
    "Sega - SG-1000" = "genesis_plus_gx_libretro"
    "Sega - Saturn" = "mednafen_saturn_libretro"
    "SNK - Neo Geo Pocket" = "mednafen_ngp_libretro"
    "SNK - Neo Geo Pocket Color" = "mednafen_ngp_libretro"
    "Sony - PlayStation" = "${playstationCore}"
    "Sony - PlayStation 2" = "pcsx2_libretro"
    "Sony - PlayStation Portable" = "ppsspp_libretro"
    "Spectravideo - SVI-318 - SVI-328" = "bluemsx_libretro"
  '';

  compressedLinuxFirmware = pkgs.compressFirmwareZstd pkgs.linux-firmware;

  trimmedLinuxFirmware =
    pkgs.runCommand "linux-firmware-trimmed"
      {
        passthru.compressFirmware = false;
      }
      ''
        mkdir -p "$out"
        cp -r --no-preserve=mode "${compressedLinuxFirmware}/lib" "$out/lib"
        rm -rf \
          "$out/lib/firmware/mellanox" \
          "$out/lib/firmware/mrvl/prestera" \
          "$out/lib/firmware/qed" \
          "$out/lib/firmware/netronome" \
          "$out/lib/firmware/dpaa2" \
          "$out/lib/firmware/cxgb4" \
          "$out/lib/firmware/bnx2x" \
          "$out/lib/firmware/liquidio" \
          "$out/lib/firmware/vxge" \
          "$out/lib/firmware/phanfw.bin"*
        ${lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 ''
          rm -rf "$out/lib/firmware/qcom"
        ''}
        find "$out/lib/firmware" -xtype l -delete
      '';

  trimmedMesa = pkgs.runCommand "mesa-opengl" { } ''
    cp -r --no-preserve=mode "${pkgs.mesa}" "$out"
    rm -rf \
      "$out/lib/libvulkan_"*.so* \
      "$out/lib/libteflon.so"* \
      "$out/lib/libVkLayer_"*.so* \
      "$out/share/vulkan"
    find "$out" -type f -exec grep -l "${pkgs.mesa}" {} + | xargs -r sed -i "s|${pkgs.mesa}|$out|g"
  '';
in
{
  options.extraLife = {
    variantId = lib.mkOption {
      type = lib.types.str;
      default = pkgs.stdenv.hostPlatform.parsed.cpu.name;
      description = "Hardware or architecture variant identifier for Extra Life.";
    };

    versionId = lib.mkOption {
      type = lib.types.str;
      default = lib.strings.trim (builtins.readFile ../../VERSION);
      description = "Release version identifier for Extra Life.";
    };
  };

  config = {
    system.nixos = {
      distroId = "extra-life";
      distroName = "Extra Life";
      variant_id = config.extraLife.variantId;
      version = config.extraLife.versionId;
      extraOSReleaseArgs = {
        VARIANT_ID = config.extraLife.variantId;
        VERSION_ID = config.extraLife.versionId;
      };
    };

    networking.hostName =
      let
        hostVariant = builtins.replaceStrings [ "_" ] [ "-" ] config.extraLife.variantId;
      in
      lib.mkDefault "extra-life-${hostVariant}";
    networking.useDHCP = lib.mkDefault false;
    networking.networkmanager.enable = lib.mkDefault false;
    networking.firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;
    };

    # Disable text console prompts on tty1-tty6 for a pure appliance boot.
    services.getty.autologinUser = lib.mkDefault null;
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    hardware.graphics = {
      enable = true;
      package = trimmedMesa;
    };
    hardware.uinput.enable = true;
    hardware.enableRedistributableFirmware = lib.mkForce false;
    hardware.wirelessRegulatoryDatabase = lib.mkDefault true;
    hardware.firmware = [
      trimmedLinuxFirmware
      pkgs.ipw2200-firmware
      pkgs.rtl8192su-firmware
      pkgs.rt5677-firmware
      pkgs.rtl8761b-firmware
      pkgs.zd1211fw
      pkgs.alsa-firmware
      pkgs.sof-firmware
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isAarch pkgs.raspberrypiWirelessFirmware;

    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxPackages;
      kernelModules = [
        "joydev"
        "uinput"
        "virtio_input"
        "xpad"
      ];
    };

    # Audio stack via PipeWire.
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = false;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Network management via ConnMan, storing persistent credentials in /storage/.cache/connman.
    services.connman = {
      enable = true;
      enableVPN = false;
    };

    # Bluetooth support via BlueZ, gated by Ludo's /storage/.cache/services/bluez.conf toggle.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    systemd.services.bluetooth.unitConfig.ConditionPathExists =
      lib.mkDefault "/storage/.cache/services/bluez.conf";

    # SSH server, gated by Ludo's /storage/.cache/services/sshd.conf toggle.
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = lib.mkDefault "yes";
        PasswordAuthentication = lib.mkDefault true;
        PermitEmptyPasswords = lib.mkDefault true;
      };
    };
    systemd.services.sshd.unitConfig.ConditionPathExists =
      lib.mkDefault "/storage/.cache/services/sshd.conf";

    # Samba file share for /storage/Retro, gated by Ludo's /storage/.cache/services/samba.conf toggle.
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "Extra Life (${config.extraLife.variantId})";
          security = "user";
          "map to guest" = "Bad User";
          "guest account" = "ludo";
        };
        Retro = {
          path = "/storage/Retro";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = "ludo";
          "force group" = "users";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      };
    };
    systemd.services.samba-smbd = {
      aliases = [ "smbd.service" ];
      unitConfig.ConditionPathExists = lib.mkDefault "/storage/.cache/services/samba.conf";
    };

    # Dedicated appliance user (UID 1000) with home directory at /storage.
    users.users.ludo = {
      isNormalUser = true;
      uid = 1000;
      group = "users";
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "input"
      ];
      home = "/storage";
      createHome = true;
      initialHashedPassword = "";
    };
    users.users.root.initialHashedPassword = lib.mkDefault "";

    security.sudo.wheelNeedsPassword = false;

    # Polkit rules allowing user ludo (UID 1000) to toggle appliance services,
    # manage ConnMan networks, and reboot or power off.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user !== "ludo") {
          return polkit.Result.NOT_HANDLED;
        }

        if (action.id === "org.freedesktop.systemd1.manage-units") {
          var unit = action.lookup("unit");
          if (
            unit === "sshd.service" ||
            unit === "smbd.service" ||
            unit === "samba-smbd.service" ||
            unit === "bluetooth.service" ||
            unit === "connman.service"
          ) {
            return polkit.Result.YES;
          }
        }

        if (
          action.id.indexOf("net.connman.") === 0 ||
          action.id.indexOf("org.freedesktop.login1.power-off") === 0 ||
          action.id.indexOf("org.freedesktop.login1.reboot") === 0 ||
          action.id.indexOf("org.freedesktop.login1.halt") === 0
        ) {
          return polkit.Result.YES;
        }

        return polkit.Result.NOT_HANDLED;
      });
    '';

    # Cage Wayland kiosk running Ludo in appliance mode (-ludos).
    services.cage = {
      enable = true;
      user = "ludo";
      program = "${ludoLauncher}";
      extraArguments = [ "-s" ];
      environment = {
        HOME = "/storage";
        XDG_CONFIG_HOME = "/storage/.config";
        XDG_DATA_HOME = "/storage/.local/share";
        XDG_CACHE_HOME = "/storage/.cache";
      };
    };

    environment.etc."ludo.toml".source = ludoToml;

    environment.pathsToLink = [
      "/lib/retroarch"
      "/share/ludo"
    ];

    environment.systemPackages = with pkgs; [
      bash
      connman
      coreutils
      libretro-cores
      ludo
      rsync
    ];

    # Persistent directory structure and FHS compatibility symlinks for ludo -ludos.
    systemd.tmpfiles.rules = [
      "d /storage 0755 ludo users -"
      "d /storage/Retro 0755 ludo users -"
      "d /storage/Retro/playlists 0755 ludo users -"
      "d /storage/Retro/roms 0755 ludo users -"
      "d /storage/Retro/savefiles 0755 ludo users -"
      "d /storage/Retro/savestates 0755 ludo users -"
      "d /storage/Retro/screenshots 0755 ludo users -"
      "d /storage/Retro/system 0755 ludo users -"
      "d /storage/Retro/thumbnails 0755 ludo users -"
      "d /storage/.cache 0755 ludo users -"
      "d /storage/.cache/services 0755 ludo users -"
      "d /storage/.cache/connman 0700 root root -"
      "d /storage/.update 0755 ludo users -"
      "L+ /var/lib/connman - - - - /storage/.cache/connman"
      "d /usr/bin 0755 root root -"
      "d /usr/sbin 0755 root root -"
      "L+ /usr/bin/systemctl - - - - /run/current-system/sw/bin/systemctl"
      "L+ /usr/bin/connmanctl - - - - /run/current-system/sw/bin/connmanctl"
      "L+ /usr/bin/bash - - - - /run/current-system/sw/bin/bash"
      "L+ /usr/sbin/shutdown - - - - /run/current-system/sw/bin/shutdown"
    ];

    nix = {
      channel.enable = false;
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    nixpkgs.flake = {
      setFlakeRegistry = false;
      setNixPath = false;
    };

    documentation = {
      enable = false;
      doc.enable = false;
      info.enable = false;
      man.enable = false;
      nixos.enable = false;
    };

    system.stateVersion = lib.mkDefault "26.05";
  };
}
