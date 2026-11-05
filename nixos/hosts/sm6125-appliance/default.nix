{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/sm6125.nix
    ../../modules/images/disk-openabl.nix
  ];

  extraLife.variantId = "sm6125";
  nixpkgs.hostPlatform = "aarch64-linux";
}
