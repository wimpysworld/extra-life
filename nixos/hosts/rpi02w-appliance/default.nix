{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/rpi02w.nix
    ../../modules/images/disk-rpi.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
