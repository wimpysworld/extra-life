{
  config,
  lib,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;
  inherit (config.extraLife) variantId;
  openablDevice = lib.toUpper variantId;

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

  boardEntries = lib.mapAttrsToList (
    id: dev:
    let
      entryFile = pkgs.writeText "extra-life-${id}.conf" ''
        title Extra Life (${dev.name})
        linux /KERNEL
        initrd /INITRD
        fdt /dtbs/${dev.dtb}
        options init=/nix/store/current-system/init ${toString config.boot.kernelParams}
      '';
    in
    "cp ${entryFile} \"$out/extra-life-${id}.conf\""
  ) socDevices;

  entriesDir = pkgs.runCommand "extra-life-bls-entries-${variantId}" { } ''
    mkdir -p "$out"
    cp ${defaultEntryConf} "$out/extra-life.conf"
    ${lib.concatStringsSep "\n" boardEntries}
  '';

  socDtbs = pkgs.runCommand "extra-life-${variantId}-dtbs" { } ''
    mkdir -p "$out/qcom"
    ${
      if dtbFiles != [ ] then
        lib.concatMapStringsSep "\n" (dtb: ''
          cp -f "${config.hardware.deviceTree.package}/${dtb}" "$out/${dtb}"
          cp -f "${config.hardware.deviceTree.package}/${dtb}" "$out/$(basename "${dtb}")"
        '') dtbFiles
      else
        ''
          for f in ${
            if variantId == "sm8550" then
              ''"${config.hardware.deviceTree.package}"/qcom/qcs8550-*.dtb "${config.hardware.deviceTree.package}"/qcom/sm8550-*.dtb''
            else
              ''"${config.hardware.deviceTree.package}"/qcom/${variantId}-*.dtb''
          }; do
            if [ -e "$f" ]; then
              cp -f "$f" "$out/qcom/$(basename "$f")"
              cp -f "$f" "$out/$(basename "$f")"
            fi
          done
        ''
    }
  '';

  openablTarball = pkgs.fetchurl {
    url = "https://github.com/OpenHandheldCollective/OpenABL/releases/download/v1.2/openabl-v1.2.tar.gz";
    hash = "sha256-KMuX0bOH8o3boo7Vf9x9ixwqws3NJq+cZyYg1Bq93U8=";
  };

  openablDir = pkgs.runCommand "extra-life-openabl-${variantId}" { } ''
    mkdir -p "$out"
    tar -xzf "${openablTarball}" --strip-components=2 -C "$out" "openabl-v1.2/${openablDevice}/abl_signed-${openablDevice}.elf"
    cat > "$out/backup_abl.sh" << 'EOF'
    #!/bin/sh

    dd if="/dev/block/by-name/abl_a" of="/sdcard/openabl/abl_a.img" bs=1M
    dd if="/dev/block/by-name/abl_b" of="/sdcard/openabl/abl_b.img" bs=1M
    EOF
    cat > "$out/flash_abl.sh" << 'EOF'
    #!/bin/sh

    dd if="/sdcard/openabl/abl_signed-${openablDevice}.elf" of="/dev/block/by-name/abl_a" bs=1M
    dd if="/sdcard/openabl/abl_signed-${openablDevice}.elf" of="/dev/block/by-name/abl_b" bs=1M
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
    "/EFI/BOOT/BOOTAA64.EFI".source = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootaa64.efi";
    "/loader/entries".source = entriesDir;
    "/dtbs".source = socDtbs;
    "/KERNEL".source = "${toplevel}/kernel";
    "/INITRD".source = "${toplevel}/initrd";
    "/SYSTEM".source = config.system.build.systemSquashfs;
  }
  //
    lib.optionalAttrs
      (builtins.elem variantId [
        "sm6115"
        "sm8250"
        "sm8550"
      ])
      {
        "/openabl".source = openablDir;
      };
}
