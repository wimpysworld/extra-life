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

  boot = {
    initrd.systemd.enable = true;
    loader = {
      grub.enable = lib.mkForce false;
      timeout = lib.mkForce 0;
    };
    kernelParams = [ "quiet" ];
  };

  systemd.services.register-nix-paths.enable = false;

  isoImage = {
    edition = "extra-life";
    makeBiosBootable = false;
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
    parted
    util-linux
  ];
}
