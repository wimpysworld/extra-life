{
  imports = [
    ../../modules/appliance.nix
    ../../modules/hardware/soc/sm8550.nix
    ../../modules/images/disk-openabl.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
