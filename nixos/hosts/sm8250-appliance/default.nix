{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/sm8250.nix
    ../../modules/images/disk-openabl.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
