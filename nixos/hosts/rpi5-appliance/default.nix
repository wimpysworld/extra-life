{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/rpi5.nix
    ../../modules/images/disk-rpi.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
