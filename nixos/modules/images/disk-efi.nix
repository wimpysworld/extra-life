{
  config,
  lib,
  pkgs,
  ...
}:
let
  toplevel = config.system.build.toplevel;
  inherit (pkgs.stdenv.hostPlatform) efiArch;
  bootEfiName = lib.toUpper "boot${efiArch}.efi";

  loaderConf = pkgs.writeText "loader.conf" ''
    default extra-life.conf
    timeout 0
    editor no
  '';

  entryConf = pkgs.writeText "extra-life.conf" ''
    title Extra Life
    linux /KERNEL
    initrd /INITRD
    options init=/nix/store/current-system/init ${toString config.boot.kernelParams}
  '';
in
{
  imports = [
    ./disk-base.nix
  ];

  image.repart.partitions."10-boot".contents = {
    "/EFI/BOOT/${bootEfiName}".source =
      "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
    "/loader/loader.conf".source = loaderConf;
    "/loader/entries/extra-life.conf".source = entryConf;
    "/KERNEL".source = "${toplevel}/kernel";
    "/INITRD".source = "${toplevel}/initrd";
    "/SYSTEM".source = config.system.build.systemSquashfs;
  };
}
