{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/qemu-guest.nix
    ../../modules/images/iso.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
