{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "mmc_block"
      "nvme"
      "sd_mod"
      "sdhci_acpi"
      "sdhci_pci"
      "uas"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];

    kernelModules = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      "bmi160_i2c"
      "goodix_ts"
      "gpd-fan"
      "i2c_designware_platform"
      "i2c_hid_acpi"
      "intel_lpss_pci"
      "mxc4005"
      "snd_hda_intel"
      "snd_sof_pci_intel_icl"
      "snd_sof_pci_intel_tgl"
    ];
  };

  hardware.cpu = {
    amd.updateMicrocode = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
    intel.updateMicrocode = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
  };
}
