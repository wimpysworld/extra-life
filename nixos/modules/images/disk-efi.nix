{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  boot = {
    growPartition = true;
    kernelParams = [
      "quiet"
      "splash"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
      timeout = 0;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/extralife-root";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  system.disableInstallerTools = true;

  system.build.diskImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    partitionTableType = "efi";
    format = "raw";
    label = "extralife-root";
    baseName = "extra-life-${pkgs.stdenv.hostPlatform.parsed.cpu.name}";
    diskSize = "auto";
    additionalSpace = "128M";
    copyChannel = false;
  };
}
