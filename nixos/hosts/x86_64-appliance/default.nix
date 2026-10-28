{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    ../../modules/appliance.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    growPartition = true;
    kernelParams = [
      "quiet"
      "splash"
    ];
    initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "nvme"
      "sd_mod"
      "sdhci_pci"
      "uas"
      "usb_storage"
      "usbhid"
      "virtio_blk"
      "virtio_gpu"
      "virtio_net"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
      timeout = 0;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/extralife-root";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  system.build.diskImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    partitionTableType = "efi";
    format = "raw";
    label = "extralife-root";
    baseName = "extra-life-x86_64";
    diskSize = "auto";
    additionalSpace = "128M";
    copyChannel = false;
  };

  system.stateVersion = "26.05";
}
