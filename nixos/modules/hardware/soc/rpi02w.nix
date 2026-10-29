{
  lib,
  ...
}:
{
  imports = [
    ./rpi-common.nix
  ];

  extraLife.variantId = lib.mkDefault "rpi02w";

  boot.kernelParams = [
    "cma=128M"
    "snd_bcm2835.enable_headphones=1"
    "snd_bcm2835.enable_hdmi=1"
  ];
}
