{
  lib,
  ...
}:
{
  imports = [
    ./rpi-common.nix
  ];

  extraLife.variantId = lib.mkDefault "rpi5";
}
