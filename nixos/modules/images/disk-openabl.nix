{
  config,
  lib,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;
  inherit (config.extraLife) variantId;

  socDevices = lib.filterAttrs (
    _id: dev: (dev.soc or "") == variantId && (dev ? dtb)
  ) config.extraLife.devices;

  dtbFiles = lib.unique (lib.mapAttrsToList (_id: dev: dev.dtb) socDevices);

  defaultEntryConf = pkgs.writeText "extra-life.conf" ''
    title Extra Life
    linux /KERNEL
    initrd /INITRD
    options init=/nix/store/current-system/init ${toString config.boot.kernelParams}
  '';

  entriesDir = pkgs.runCommand "extra-life-bls-entries-${variantId}" { } ''
    mkdir -p "$out"
    cp ${defaultEntryConf} "$out/extra-life.conf"
  '';

  socDtbs = pkgs.runCommand "extra-life-${variantId}-dtbs" { } ''
    mkdir -p "$out/qcom"
    ${lib.concatMapStringsSep "\n" (dtb: ''
      cp -f "${config.hardware.deviceTree.package}/${dtb}" "$out/${dtb}"
      cp -f "${config.hardware.deviceTree.package}/${dtb}" "$out/$(basename "${dtb}")"
    '') dtbFiles}
  '';

  openablTarball = pkgs.fetchurl {
    url = "https://github.com/OpenHandheldCollective/OpenABL/releases/download/v1.2/openabl-v1.2.tar.gz";
    hash = "sha256-KMuX0bOH8o3boo7Vf9x9ixwqws3NJq+cZyYg1Bq93U8=";
  };

  openablDir = pkgs.runCommand "extra-life-openabl-${variantId}" { } ''
    mkdir -p "$out"
    tar -xzf "${openablTarball}" --strip-components=2 -C "$out" "openabl-v1.2/SM6115/abl_signed-SM6115.elf"
    cat > "$out/backup_abl.sh" << 'EOF'
    #!/bin/sh

    dd if="/dev/block/by-name/abl_a" of="/sdcard/openabl/abl_a.img" bs=1M
    dd if="/dev/block/by-name/abl_b" of="/sdcard/openabl/abl_b.img" bs=1M
    EOF
    cat > "$out/flash_abl.sh" << 'EOF'
    #!/bin/sh

    dd if="/sdcard/openabl/abl_signed-SM6115.elf" of="/dev/block/by-name/abl_a" bs=1M
    dd if="/sdcard/openabl/abl_signed-SM6115.elf" of="/dev/block/by-name/abl_b" bs=1M
    EOF
    cat > "$out/restore_backup_abl.sh" << 'EOF'
    #!/bin/sh

    dd if="/sdcard/openabl/abl_a.img" of="/dev/block/by-name/abl_a" bs=1M
    dd if="/sdcard/openabl/abl_b.img" of="/dev/block/by-name/abl_b" bs=1M
    EOF
    chmod 0755 "$out/backup_abl.sh" "$out/flash_abl.sh" "$out/restore_backup_abl.sh"
  '';
in
{
  imports = [
    ./disk-base.nix
  ];

  image.repart.partitions."10-boot".contents = {
    "/loader/entries".source = entriesDir;
    "/dtbs".source = socDtbs;
    "/KERNEL".source = "${toplevel}/kernel";
    "/INITRD".source = "${toplevel}/initrd";
    "/SYSTEM".source = config.system.build.systemSquashfs;
  }
  // lib.optionalAttrs (variantId == "sm6115") {
    "/openabl".source = openablDir;
  };
}
