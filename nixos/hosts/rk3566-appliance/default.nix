{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/rk3566.nix
    ../../modules/images/disk-rk3566.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
