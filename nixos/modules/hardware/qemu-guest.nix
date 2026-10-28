{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_gpu"
    "virtio_net"
    "virtio_pci"
    "virtio_scsi"
  ];

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
