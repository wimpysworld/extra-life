{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/pc.nix
    ../../modules/hardware/qemu-guest.nix
    ../../modules/images/disk-efi.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
