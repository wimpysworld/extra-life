{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/rk3588.nix
    ../../modules/images/disk-rk3588.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  extraLife.variantId = "rk3588";
}
