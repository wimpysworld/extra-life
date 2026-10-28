{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];

  boot.loader.timeout = lib.mkForce 0;
  boot.kernelParams = [ "quiet" ];

  isoImage = {
    edition = "extra-life";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  # Enable SSH by default on the live ISO for vm-retro ROM transfers and installation.
  systemd.tmpfiles.rules = [
    "f /storage/.cache/services/sshd.conf 0644 ludo users -"
  ];

  environment.systemPackages = with pkgs; [
    dosfstools
    e2fsprogs
    gptfdisk
    nixos-install-tools
    parted
    util-linux
  ];
}
