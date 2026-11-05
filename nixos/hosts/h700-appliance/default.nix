{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/h700.nix
    ../../modules/images/disk-h700.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  extraLife.variantId = "h700";
}
