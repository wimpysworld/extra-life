{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;
  toplevelName = baseNameOf toplevel;
  inherit (config.extraLife) variantId versionId;
  tarName = "extra-life-${variantId}-${versionId}.tar";

  systemSquashfs = pkgs.callPackage "${modulesPath}/../lib/make-squashfs.nix" {
    fileName = "SYSTEM";
    storeContents = [ toplevel ];
    comp = "zstd -Xcompression-level 19";
    pseudoFiles = [
      "current-system s 0777 0 0 ${toplevelName}"
    ];
  };

  otaBundle =
    pkgs.runCommand "extra-life-ota-${variantId}-${versionId}"
      {
        nativeBuildInputs = [
          pkgs.coreutils
          pkgs.gnutar
        ];
      }
      ''
        mkdir -p "$out" bundle
        cp -L "${toplevel}/kernel" bundle/KERNEL
        cp -L "${toplevel}/initrd" bundle/INITRD
        cp -L "${systemSquashfs}" bundle/SYSTEM
        (
          cd bundle
          sha256sum KERNEL > KERNEL.sha256
          sha256sum INITRD > INITRD.sha256
          sha256sum SYSTEM > SYSTEM.sha256
          sha256sum KERNEL INITRD SYSTEM > SHA256SUMS
        )
        tar --sort=name --mtime='@1' --owner=0 --group=0 --numeric-owner \
          -cf "$out/${tarName}" -C bundle .
        tar_sha256="$(sha256sum "$out/${tarName}" | cut -d' ' -f1)"
        printf '%s  %s\n' "$tar_sha256" "${tarName}" > "$out/${tarName}.sha256"
        cat > "$out/releases.json" <<EOF
        [
          {
            "name": "v${versionId}",
            "assets": [
              {
                "name": "${tarName}",
                "device": "${variantId}",
                "sha256": "$tar_sha256",
                "browser_download_url": "https://extralife-ota.wimpys.world/${tarName}"
              }
            ]
          }
        ]
        EOF
      '';
in
{
  imports = [
    "${modulesPath}/image/repart.nix"
  ];

  boot = {
    kernelParams = [
      "quiet"
      "splash"
    ];
    loader = {
      grub.enable = false;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = false;
      timeout = 0;
    };
  };

  system.image = {
    id = "extra-life-${variantId}";
    version = versionId;
  };

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "mode=0755"
        "size=25%"
      ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-label/EXTRALIFE";
      fsType = "vfat";
      options = [
        "ro"
        "umask=0022"
      ];
      neededForBoot = true;
    };

    "/nix/store" = {
      device = "/boot/SYSTEM";
      fsType = "squashfs";
      options = [
        "loop"
        "ro"
        "threads=multi"
      ];
      depends = [ "/boot" ];
      neededForBoot = true;
    };

    "/storage" = {
      device = "/dev/disk/by-label/STORAGE";
      fsType = "ext4";
      autoResize = true;
      neededForBoot = true;
    };
  };

  boot.initrd = {
    systemd.enable = true;
    supportedFilesystems = [
      "vfat"
      "ext4"
      "squashfs"
    ];
    availableKernelModules = [
      "loop"
      "squashfs"
      "vfat"
      "nls_cp437"
      "nls_iso8859_1"
      "ext4"
    ];
    kernelModules = [
      "loop"
      "squashfs"
      "vfat"
      "nls_cp437"
      "nls_iso8859_1"
    ];

    systemd.initrdBin = [
      pkgs.coreutils
      pkgs.gnutar
      pkgs.util-linux
    ];

    systemd.tmpfiles.settings."10-extra-life"."/boot"."L+".argument = "/sysroot/boot";

    systemd.services.extra-life-grow-storage = {
      description = "Expand Extra Life STORAGE partition to fill disk";
      wantedBy = [ "initrd.target" ];
      after = [ "dev-disk-by\\x2dlabel-STORAGE.device" ];
      before = [
        "systemd-fsck@dev-disk-by\\x2dlabel-STORAGE.service"
        "sysroot-storage.mount"
      ];
      requires = [ "dev-disk-by\\x2dlabel-STORAGE.device" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        partDev="$(readlink -f /dev/disk/by-label/STORAGE)"
        partName="''${partDev#/dev/}"
        if [[ ! -r "/sys/class/block/$partName/partition" ]]; then
          exit 0
        fi
        partNum="$(< "/sys/class/block/$partName/partition")"
        partStart="$(< "/sys/class/block/$partName/start")"
        partSectors="$(< "/sys/class/block/$partName/size")"
        parentSys="$(readlink -f "/sys/class/block/$partName/..")"
        parentName="$(basename "$parentSys")"
        parentDev="/dev/$parentName"
        diskSectors="$(< "/sys/class/block/$parentName/size")"
        if (( diskSectors - (partStart + partSectors) > 4096 )); then
          echo ", +" | sfdisk --no-reread -N "$partNum" "$parentDev" || true
          partx -u "$parentDev" || true
        fi
      '';
    };

    systemd.services.extra-life-apply-update = {
      description = "Apply Extra Life OTA update from /storage/.update";
      wantedBy = [ "initrd.target" ];
      after = [
        "sysroot-boot.mount"
        "sysroot-storage.mount"
      ];
      before = [
        "sysroot-nix-store.mount"
        "initrd-find-etc.service"
        "initrd-find-nixos-closure.service"
      ];
      unitConfig = {
        DefaultDependencies = false;
        RequiresMountsFor = [
          "/sysroot/boot"
          "/sysroot/storage"
        ];
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        ln -sfn /sysroot/boot /boot

        if [[ -f /sysroot/boot/BOOT_TRIAL ]]; then
          trial="$(< /sysroot/boot/BOOT_TRIAL)"
          if [[ "$trial" == "0" ]]; then
            mount -o remount,rw /sysroot/boot
            echo "1" > /sysroot/boot/BOOT_TRIAL
            sync
            mount -o remount,ro /sysroot/boot
          elif [[ -f /sysroot/boot/SYSTEM.prev ]]; then
            echo "extra-life-update: previous trial boot failed, rolling back" > /dev/kmsg
            mount -o remount,rw /sysroot/boot
            for f in KERNEL INITRD SYSTEM; do
              if [[ -f "/sysroot/boot/$f.prev" ]]; then
                mv -f "/sysroot/boot/$f.prev" "/sysroot/boot/$f"
              fi
            done
            rm -f /sysroot/boot/BOOT_TRIAL
            sync
            mount -o remount,ro /sysroot/boot
            systemctl --force reboot
          fi
        fi

        shopt -s nullglob
        tarballs=(/sysroot/storage/.update/*.tar)
        if (( ''${#tarballs[@]} == 0 )); then
          exit 0
        fi

        tarball="''${tarballs[0]}"
        echo "extra-life-update: found update archive $tarball" > /dev/kmsg

        work="/sysroot/storage/.update/.staging"
        rm -rf "$work"
        mkdir -p "$work"

        if ! tar -xf "$tarball" -C "$work"; then
          echo "extra-life-update: tar extraction failed, deleting archive" > /dev/kmsg
          rm -rf "$work" "$tarball"
          exit 0
        fi

        src="$work"
        for candidate in "$work"/*/target "$work"/target; do
          if [[ -d "$candidate" ]]; then
            src="$candidate"
            break
          fi
        done

        if [[ ! -f "$src/SHA256SUMS" ]] || ! (cd "$src" && sha256sum -c SHA256SUMS); then
          echo "extra-life-update: SHA-256 check failed, aborting update" > /dev/kmsg
          rm -rf "$work" "$tarball"
          exit 0
        fi

        mount -o remount,rw /sysroot/boot

        for f in KERNEL INITRD SYSTEM; do
          cp -f "$src/$f" "/sysroot/boot/$f.new"
        done
        sync

        need_reboot=0
        if ! cmp -s "/sysroot/boot/KERNEL" "/sysroot/boot/KERNEL.new" || \
           ! cmp -s "/sysroot/boot/INITRD" "/sysroot/boot/INITRD.new"; then
          need_reboot=1
        fi

        for f in KERNEL INITRD SYSTEM; do
          if [[ -f "/sysroot/boot/$f" ]]; then
            mv -f "/sysroot/boot/$f" "/sysroot/boot/$f.prev"
          fi
          mv -f "/sysroot/boot/$f.new" "/sysroot/boot/$f"
        done

        if (( need_reboot == 1 )); then
          echo "0" > /sysroot/boot/BOOT_TRIAL
        else
          echo "1" > /sysroot/boot/BOOT_TRIAL
        fi
        sync
        mount -o remount,ro /sysroot/boot

        rm -rf "$work" /sysroot/storage/.update/*.tar
        sync

        if (( need_reboot == 1 )); then
          echo "extra-life-update: KERNEL or INITRD changed, rebooting" > /dev/kmsg
          systemctl --force reboot
        fi
        echo "extra-life-update: SYSTEM updated, continuing boot" > /dev/kmsg
      '';
    };
  };

  systemd.services.extra-life-mark-boot-good = {
    description = "Clear Extra Life OTA trial boot marker after successful boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "cage-tty1.service" ];
    unitConfig.ConditionPathExists = "/boot/BOOT_TRIAL";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mount -o remount,rw /boot
      rm -f /boot/BOOT_TRIAL
      sync
      mount -o remount,ro /boot
    '';
  };

  image.repart = {
    name = "extra-life-${variantId}";
    partitions = {
      "10-boot".repartConfig = {
        Type = "esp";
        Format = "vfat";
        Label = "EXTRALIFE";
        SizeMinBytes = "3G";
        SizeMaxBytes = "3G";
      };
      "20-storage".repartConfig = {
        Type = "linux-generic";
        Format = "ext4";
        Label = "STORAGE";
        SizeMinBytes = "512M";
        GrowFileSystem = true;
      };
    };
  };

  system.build = {
    inherit systemSquashfs otaBundle;
    diskImage = lib.mkDefault config.image.repart.image;
  };
}
