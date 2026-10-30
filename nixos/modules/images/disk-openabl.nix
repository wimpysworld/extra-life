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
  };
}
