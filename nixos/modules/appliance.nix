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
    exec ${pkgs.ludo}/bin/ludo -ludos
  '';

  ludoToml = pkgs.writeText "ludo.toml" ''
    video_fullscreen = true
    video_dark_mode = true
    cores_dir = "/run/current-system/sw/lib/retroarch/cores"
    assets_dir = "${pkgs.ludo}/share/ludo/assets"
    database_dir = "${pkgs.ludo}/share/ludo/database"
    files_dir = "/storage/Retro/roms"
    roms_dir = "/storage/Retro/roms"
    playlists_dir = "/storage/Retro/playlists"
    savefiles_dir = "/storage/Retro/savefiles"
    savestates_dir = "/storage/Retro/savestates"
    screenshots_dir = "/storage/Retro/screenshots"
    system_dir = "/storage/Retro/system"
    thumbnail_dir = "/storage/Retro/thumbnails"
    thumbnails_dir = "/storage/Retro/thumbnails"
  '';
in
{
  networking.hostName = lib.mkDefault "extra-life";
  networking.useDHCP = lib.mkDefault false;
  networking.networkmanager.enable = lib.mkDefault false;
  networking.firewall.enable = lib.mkDefault false;

  # Disable text console prompts on tty1-tty6 for a pure appliance boot.
  services.getty.autologinUser = lib.mkDefault null;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  hardware.graphics.enable = true;
  hardware.uinput.enable = true;
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.kernelModules = [
    "joydev"
    "uinput"
    "virtio_input"
    "xpad"
  ];

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
        "server string" = "Extra Life Appliance";
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
  # manage ConnMan networks, trigger OTA updates, and reboot or power off.
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
          unit === "connman.service" ||
          unit === "extra-life-update.service"
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

  # Binary-cache over-the-air update service (zero on-device Nix evaluation).
  systemd.services.extra-life-update = {
    description = "Extra Life binary-cache OTA system update";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -euo pipefail
      manifest="/storage/.update/target-system"
      if [[ ! -f "$manifest" ]]; then
        echo "extra-life-update: no target system closure found at $manifest" >&2
        exit 1
      fi
      read -r store_path < "$manifest"
      if [[ ! "$store_path" =~ ^/nix/store/[a-z0-9]{32}-.+ ]]; then
        echo "extra-life-update: invalid store path: $store_path" >&2
        exit 1
      fi
      ${config.nix.package}/bin/nix-store --realise "$store_path"
      ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set "$store_path"
      "$store_path/bin/switch-to-configuration" switch
      rm -f "$manifest"
    '';
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
}
