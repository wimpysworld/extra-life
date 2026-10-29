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

  sortedDeviceIds = builtins.sort builtins.lessThan (builtins.attrNames socDevices);

  defaultDtbLine =
    if sortedDeviceIds == [ ] then
      ""
    else
      "devicetree /dtbs/${socDevices.${builtins.head sortedDeviceIds}.dtb}\n";

  loaderConf = pkgs.writeText "loader.conf" ''
    default extra-life*.conf
    timeout 0
    editor no
  '';

  defaultEntryConf = pkgs.writeText "extra-life.conf" (
    ''
      title Extra Life
      linux /KERNEL
      initrd /INITRD
    ''
    + defaultDtbLine
    + ''
      options init=/nix/store/current-system/init ${toString config.boot.kernelParams}
    ''
  );

  boardEntries = lib.mapAttrsToList (
    id: dev:
    let
      entryFile = pkgs.writeText "extra-life-${id}.conf" ''
        title Extra Life (${dev.name})
        linux /KERNEL
        initrd /INITRD
        devicetree /dtbs/${dev.dtb}
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
in
{
  imports = [
    ./disk-base.nix
  ];

  image.repart.partitions."10-boot".contents = {
    "/EFI/BOOT/BOOTAA64.EFI".source = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootaa64.efi";
    "/loader/loader.conf".source = loaderConf;
    "/loader/entries".source = entriesDir;
    "/dtbs/qcom".source = "${config.hardware.deviceTree.package}/qcom";
    "/KERNEL".source = "${toplevel}/kernel";
    "/INITRD".source = "${toplevel}/initrd";
    "/SYSTEM".source = config.system.build.systemSquashfs;
  };
}
