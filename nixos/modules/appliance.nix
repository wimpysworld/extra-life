{
  config,
  lib,
  pkgs,
  ...
}:
let
  ludoLauncher = pkgs.writeShellScript "extra-life-ludo" ''
    if [ -r /run/extra-life-board.env ]; then
      set -a
      . /run/extra-life-board.env
      set +a
    fi
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
        chmod -R u+w "$out/lib"
        rm -rf \
          "$out/lib/firmware/mellanox" \
          "$out/lib/firmware/mrvl/prestera" \
          "$out/lib/firmware/qed" \
          "$out/lib/firmware/netronome" \
          "$out/lib/firmware/dpaa2" \
          "$out/lib/firmware/cxgb3" \
          "$out/lib/firmware/cxgb4" \
          "$out/lib/firmware/bnx2" \
          "$out/lib/firmware/bnx2x" \
          "$out/lib/firmware/liquidio" \
          "$out/lib/firmware/vxge" \
          "$out/lib/firmware/phanfw.bin"* \
          "$out/lib/firmware/qlogic" \
          "$out/lib/firmware/ql2"*_fw.bin* \
          "$out/lib/firmware/cbfw"* \
          "$out/lib/firmware/ctfw"* \
          "$out/lib/firmware/ct2fw"* \
          "$out/lib/firmware/myri10ge"* \
          "$out/lib/firmware/slicoss" \
          "$out/lib/firmware/tehuti" \
          "$out/lib/firmware/cavium" \
          "$out/lib/firmware/isci" \
          "$out/lib/firmware/advansys" \
          "$out/lib/firmware/hfi1_"*.fw* \
          "$out/lib/firmware/ueagle-atm" \
          "$out/lib/firmware/go7007" \
          "$out/lib/firmware/moxa" \
          "$out/lib/firmware/dvb"* \
          "$out/lib/firmware/sms1xxx"* \
          "$out/lib/firmware/isdbt"* \
          "$out/lib/firmware/cmmb"* \
          "$out/lib/firmware/tdmb"* \
          "$out/lib/firmware/tlg2300"* \
          "$out/lib/firmware/f2255"* \
          "$out/lib/firmware/amdgpu/isp"* \
          "$out/lib/firmware/amdgpu/arcturus_"* \
          "$out/lib/firmware/amdgpu/aldebaran_"* \
          "$out/lib/firmware/amdgpu/vega20_"* \
          "$out/lib/firmware/amdgpu/gc_9_4_3_"* \
          "$out/lib/firmware/amdgpu/gc_9_4_4_"* \
          "$out/lib/firmware/amdgpu/psp_13_0_6_"* \
          "$out/lib/firmware/amdgpu/psp_13_0_12_"* \
          "$out/lib/firmware/amdgpu/psp_13_0_14_"* \
          "$out/lib/firmware/amdgpu/sdma_4_4_2"* \
          "$out/lib/firmware/amdgpu/sdma_4_4_5"* \
          "$out/lib/firmware/amdgpu/vcn_4_0_3"* \
          "$out/lib/firmware/amdgpu/smu_13_0_6"* \
          "$out/lib/firmware/amdgpu/smu_13_0_14"* \
          "$out/lib/firmware/intel/vsc" \
          "$out/lib/firmware/intel/ipu" \
          "$out/lib/firmware/intel/qat" \
          "$out/lib/firmware/intel/ice" \
          "$out/lib/firmware/qat_"* \
          "$out/lib/firmware/ath10k/QCA4019" \
          "$out/lib/firmware/ath10k/QCA99"* \
          "$out/lib/firmware/ath10k/QCA9888" \
          "$out/lib/firmware/ath11k/IPQ"* \
          "$out/lib/firmware/ath11k/QCN9074" \
          "$out/lib/firmware/ath12k/IPQ"* \
          "$out/lib/firmware/ath12k/QCN9274" \
          "$out/lib/firmware/mediatek/mt7996" \
          "$out/lib/firmware/mediatek/mt7988" \
          "$out/lib/firmware/mediatek/mt7987" \
          "$out/lib/firmware/mediatek/mt7981"* \
          "$out/lib/firmware/mediatek/mt7986"* \
          "$out/lib/firmware/mediatek/mt7915"* \
          "$out/lib/firmware/nvidia/"*/gsp/*-535.113.01.bin* \
          "$out/lib/firmware/nvidia/gv100" \
          "$out/lib/firmware/nvidia/gp100" \
          "$out/lib/firmware/nvidia/ga100" \
          "$out/lib/firmware/nvidia/gh100" \
          "$out/lib/firmware/nvidia/gb100" \
          "$out/lib/firmware/nvidia/gb102"
        ${lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 ''
          rm -rf \
            "$out/lib/firmware/qcom" \
            "$out/lib/firmware/amlogic" \
            "$out/lib/firmware/meson" \
            "$out/lib/firmware/amphion" \
            "$out/lib/firmware/arm" \
            "$out/lib/firmware/powervr" \
            "$out/lib/firmware/rockchip" \
            "$out/lib/firmware/s5p-mfc"* \
            "$out/lib/firmware/nvidia/tegra"* \
            "$out/lib/firmware/nvidia/gk20a" \
            "$out/lib/firmware/nvidia/gm20b" \
            "$out/lib/firmware/nvidia/gp10b"
        ''}
        declare -A max_rev
        for f in "$out"/lib/firmware/iwlwifi-*.ucode.zst "$out"/lib/firmware/intel/iwlwifi/iwlwifi-*.ucode.zst; do
          [ -e "$f" ] && [ ! -L "$f" ] || continue
          base="$(basename "$f" .ucode.zst)"
          prefix="''${base%-*}"
          rev="''${base##*-}"
          num="''${rev#c}"
          if [[ "$num" =~ ^[0-9]+$ ]] && (( num <= 100 )); then
            cur="''${max_rev[$prefix]:--1}"
            if (( num > cur )); then
              max_rev[$prefix]="$num"
            fi
          fi
        done
        for f in "$out"/lib/firmware/iwlwifi-*.ucode.zst "$out"/lib/firmware/intel/iwlwifi/iwlwifi-*.ucode.zst; do
          [ -e "$f" ] && [ ! -L "$f" ] || continue
          base="$(basename "$f" .ucode.zst)"
          prefix="''${base%-*}"
          rev="''${base##*-}"
          num="''${rev#c}"
          if ! ( [[ "$num" =~ ^[0-9]+$ ]] && (( num == ''${max_rev[$prefix]:--1} )) ); then
            rm -f "$f"
          fi
        done
        find "$out/lib/firmware" -xtype l -delete
      '';

  trimmedMesa =
    pkgs.runCommand "mesa-${pkgs.mesa.version}"
      {
        nativeBuildInputs = [ pkgs.patchelf ];
      }
      ''
        cp -r --no-preserve=mode "${pkgs.mesa}" "$out"
        chmod -R u+w "$out"
        rm -rf \
          "$out/bin" \
          "$out/lib/libvulkan_"*.so* \
          "$out/lib/libteflon.so"* \
          "$out/lib/libVkLayer_"*.so* \
          "$out/share/vulkan"
        for gallium in "$out"/lib/libgallium*.so*; do
          if [ -f "$gallium" ] && [ ! -L "$gallium" ]; then
            rpath="$(patchelf --print-rpath "$gallium")"
            IFS=':' read -ra rpath_entries <<< "$rpath"
            for entry in "''${rpath_entries[@]}"; do
              case "$entry" in
                *-llvm-*-lib/lib)
                  cp -P --no-preserve=mode "$entry"/libLLVM*.so* "$out/lib/"
                  new_rpath="''${rpath//$entry/$out/lib}"
                  patchelf --set-rpath "$new_rpath" "$gallium"
                  ;;
              esac
            done
          fi
        done
        while IFS= read -r -d "" elf; do
          rpath="$(patchelf --print-rpath "$elf" 2>/dev/null || true)"
          if [[ "$rpath" == *"${pkgs.mesa}"* ]]; then
            patchelf --set-rpath "$(echo "$rpath" | sed "s|${pkgs.mesa}|$out|g")" "$elf"
          fi
        done < <(find "$out/lib" -type f -name '*.so*' -print0)
        find "$out/share" -type f -exec grep -l "${pkgs.mesa}" {} + | xargs -r sed -i "s|${pkgs.mesa}|$out|g"
        find "$out/lib" -type f -name '*.so*' -exec grep -l "${pkgs.mesa}" {} + | xargs -r sed -i "s|${pkgs.mesa}|$out|g"
        if grep -rn "${pkgs.mesa}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.mesa}"
          exit 1
        fi
        while IFS= read -r -d "" link; do
          target="$(readlink "$link")"
          if [[ "$target" == *"${pkgs.mesa}"* ]]; then
            echo "ERROR: symlink $link points to $target"
            exit 1
          fi
        done < <(find "$out" -type l -print0)
      '';

  trimmedSamba =
    pkgs.runCommand "samba-${pkgs.samba.version}"
      {
        nativeBuildInputs = [
          pkgs.patchelf
          pkgs.bintools
        ];
      }
      ''
        mkdir -p "$out/bin" "$out/lib/samba" "$out/libexec/samba"
        ln -s bin "$out/sbin"

        for bin in smbd nmbd smbpasswd smbcontrol testparm; do
          cp --no-preserve=mode "${pkgs.samba}/bin/$bin" "$out/bin/$bin"
        done

        for helper in \
          rpcd_classic \
          rpcd_epmapper \
          rpcd_fsrvp \
          rpcd_lsad \
          rpcd_mdssvc \
          rpcd_rpcecho \
          rpcd_spoolss \
          rpcd_winreg \
          samba-bgqd \
          samba-dcerpcd; do
          if [ -e "${pkgs.samba}/libexec/samba/$helper" ]; then
            cp --no-preserve=mode "${pkgs.samba}/libexec/samba/$helper" "$out/libexec/samba/$helper"
          fi
        done

        if [ -d "${pkgs.samba}/share/samba" ]; then
          mkdir -p "$out/share"
          cp -r --no-preserve=mode "${pkgs.samba}/share/samba" "$out/share/samba"
          find "$out/share/samba" -name '*.py' -delete
        fi

        cp -P --no-preserve=mode \
          "${pkgs.talloc}"/lib/libtalloc.so* \
          "${pkgs.talloc}"/lib/libtalloc-compat1*.so \
          "${pkgs.tdb}"/lib/libtdb.so* \
          "${pkgs.tevent}"/lib/libtevent.so* \
          "$out/lib/"

        for modDir in auth idmap krb5 ldb nss_info pdb vfs; do
          if [ -d "${pkgs.samba}/lib/samba/$modDir" ]; then
            cp -r --no-preserve=mode "${pkgs.samba}/lib/samba/$modDir" "$out/lib/samba/$modDir"
          fi
        done

        changed=1
        while [ "$changed" -eq 1 ]; do
          changed=0
          while IFS= read -r -d "" elf; do
            for needed in $(patchelf --print-needed "$elf" 2>/dev/null); do
              case "$needed" in
                *python*|*pytalloc*|*pyldb*|*smbtorture*)
                  continue
                  ;;
              esac
              if [ -e "$out/lib/$needed" ] || [ -e "$out/lib/samba/$needed" ]; then
                continue
              fi
              if [ -e "${pkgs.samba}/lib/$needed" ]; then
                base="''${needed%%.so*}"
                cp -P --no-preserve=mode "${pkgs.samba}/lib/$base".so* "$out/lib/"
                changed=1
              elif [ -e "${pkgs.samba}/lib/samba/$needed" ]; then
                cp -P --no-preserve=mode "${pkgs.samba}/lib/samba/$needed" "$out/lib/samba/"
                changed=1
              fi
            done
          done < <(find "$out/bin" "$out/libexec" "$out/lib" -type f -print0)
        done

        while IFS= read -r -d "" elf; do
          chmod 0755 "$elf"
          rpath=$(patchelf --print-rpath "$elf" 2>/dev/null || true)
          if [ -n "$rpath" ]; then
            cleaned=$(echo "$rpath" | sed \
              -e "s|${pkgs.samba}/lib/samba||g" \
              -e "s|${pkgs.samba}/lib||g" \
              -e "s|${pkgs.talloc}/lib||g" \
              -e "s|${pkgs.tdb}/lib||g" \
              -e "s|${pkgs.tevent}/lib||g" \
              -e 's|::*|:|g' \
              -e 's|^:||' \
              -e 's|:$||')
            patchelf --set-rpath "$out/lib:$out/lib/samba''${cleaned:+:$cleaned}" "$elf"
            patchelf --shrink-rpath "$elf"
          fi
          strip --strip-unneeded "$elf"
        done < <(find "$out/bin" "$out/libexec" "$out/lib" -type f -print0)

        find "$out" -type f -exec grep -l "${pkgs.samba}" {} + | xargs -r sed -i "s|${pkgs.samba}|$out|g"

        for bin in "$out"/sbin/* "$out"/bin/* "$out"/libexec/samba/*; do
          echo "Checking ldd for $bin"
          ldd_out=$(ldd "$bin")
          if echo "$ldd_out" | grep -q "not found"; then
            echo "Missing libraries for $bin:"
            echo "$ldd_out"
            exit 1
          fi
        done

        if grep -rn "${pkgs.samba}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.samba}"
          exit 1
        fi
        if grep -rn "${pkgs.python3}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.python3}"
          exit 1
        fi
        if grep -rn "${pkgs.talloc}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.talloc}"
          exit 1
        fi
        if grep -rn "${pkgs.tdb}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.tdb}"
          exit 1
        fi
        if grep -rn "${pkgs.tevent}" "$out"; then
          echo "ERROR: residual reference to ${pkgs.tevent}"
          exit 1
        fi
      '';
in
{
  imports = [
    ./hardware/boards
  ];

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
    networking.resolvconf.enable = false;
    networking.firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;
      logRefusedConnections = lib.mkDefault false;
    };

    # Disable text console prompts on tty1-tty6 for a pure appliance boot.
    console.enable = false;
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
      bcache.enable = false;
      kexec.enable = false;
      swraid.enable = false;
      initrd.systemd = {
        fido2.enable = false;
        tpm2.enable = false;
      };
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
      package = trimmedSamba;
      openFirewall = true;
      nmbd.enable = false;
      winbindd.enable = false;
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
    security.wrappers = lib.mkIf config.services.samba.enable {
      "mount.cifs".enable = false;
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
      enable = lib.mkForce false;
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
      enable = lib.mkForce false;
      doc.enable = lib.mkForce false;
      info.enable = lib.mkForce false;
      man.enable = lib.mkForce false;
      nixos.enable = lib.mkForce false;
    };

    system = {
      activatable = false;
      disableInstallerTools = true;
      etc.overlay.enable = true;
      forbiddenDependenciesRegexes = [
        "perl"
        "python3"
        "gtk\\+3"
        "xwayland"
        "retroarch"
        "llvm-.*-lib"
      ];
      nixos-init.enable = true;
      nssModules = lib.mkForce [ ];
      stateVersion = lib.mkDefault "26.05";
      switch.enable = false;
    };

    i18n = {
      defaultLocale = "C.UTF-8";
      supportedLocales = [ "C.UTF-8/UTF-8" ];
    };

    security.sudo.enable = false;
    users = {
      manageLingering = false;
      mutableUsers = false;
    };
    environment.stub-ld.enable = false;
    environment.variables.PAGER = lib.mkForce "cat";
    environment.defaultPackages = lib.mkForce [ ];
    environment.corePackages =
      with pkgs;
      lib.mkForce [
        bashInteractive
        coreutils
        gnugrep
        gnused
        iproute2
        iputils
        procps
        shadow.su
        systemd
        util-linux
      ];

    programs = {
      bash.completion.enable = false;
      fuse.enable = false;
      less.enable = lib.mkForce false;
      nano.enable = false;
    };

    fonts.fontconfig.enable = false;

    xdg = {
      autostart.enable = false;
      icons.enable = false;
      menus.enable = false;
      mime.enable = false;
      portal.enable = false;
      sounds.enable = false;
    };

    services = {
      logrotate.enable = false;
      lvm.enable = false;
      nscd.enable = false;
      userborn.enable = true;
    };

    systemd.coredump.enable = false;
    systemd.oomd.enable = false;
    systemd.shutdownRamfs.enable = false;
    systemd.services.systemd-importd.enable = false;
  };
}
