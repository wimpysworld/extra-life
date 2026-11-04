{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/rk3326.nix
    ../../modules/images/disk-rk3326.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  extraLife.variantId = "rk3326";
}
