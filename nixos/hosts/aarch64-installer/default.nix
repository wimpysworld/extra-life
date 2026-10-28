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
    "${modulesPath}/profiles/qemu-guest.nix"
    ../../modules/appliance.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.loader.timeout = lib.mkForce 0;
  boot.kernelParams = [ "quiet" ];

  isoImage = {
    edition = "extra-life";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

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

  system.stateVersion = "26.05";
}
