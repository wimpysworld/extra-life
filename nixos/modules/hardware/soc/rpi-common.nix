{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../cases
  ];

  hardware = {
    deviceTree.enable = true;
    firmware = [
      pkgs.raspberrypiWirelessFirmware
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi;

    initrd.availableKernelModules = [
      "mmc_block"
      "sdhci_iproc"
      "bcm2835_mmc"
      "sdhost"
      "pcie_brcmstb"
      "rp1"
      "rp1_pio"
      "pinctrl_rp1"
      "reset_raspberrypi"
      "vc4"
      "v3d"
      "drm_kms_helper"
      "usbhid"
      "xhci_pci"
      "dwc2"
    ];

    kernelModules = [
      "vc4"
      "v3d"
      "snd_bcm2835"
      "brcmfmac"
      "hci_uart"
      "btbcm"
      "i2c_bcm2835"
      "i2c_dev"
      "gpio_keys"
      "pwm_bcm2835"
    ];

    kernelParams = lib.optionals (config.extraLife.variantId != "rpi02w") [
      "cma=256M"
      "snd_bcm2835.enable_headphones=1"
      "snd_bcm2835.enable_hdmi=1"
    ];
  };

  environment.pathsToLink = [
    "/share/alsa/ucm2"
  ];

  environment.systemPackages = [
    pkgs.alsa-ucm-conf
  ];
}
