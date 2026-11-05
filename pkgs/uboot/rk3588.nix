{
  lib,
  buildUBoot,
  armTrustedFirmwareRK3588,
  rkbin,
  # Orange Pi 5, Retro Lite CM5, and RetrOLED CM5 share the RK3588S SoC and
  # boot media layout; board-specific kernel DTBs are selected via extlinux.conf
  # (GameForce ACE overrides defconfig with gameforce-ace-rk3588s_defconfig).
  defconfig ? "orangepi-5-rk3588s_defconfig",
}:
buildUBoot {
  inherit defconfig;
  extraConfig = ''
    CONFIG_PCI=y
    CONFIG_PCIE_DW_ROCKCHIP=y
    CONFIG_NVME_PCI=y
    CONFIG_ROCKCHIP_SFC=y
    CONFIG_SPI_FLASH_SFDP_SUPPORT=y
    CONFIG_CMD_PCI=y
    CONFIG_CMD_USB=y
  '';
  extraMeta = {
    platforms = [ "aarch64-linux" ];
    maintainers = with lib.maintainers; [ flexiondotorg ];
  };
  env = {
    BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
    ROCKCHIP_TPL = rkbin.TPL_RK3588;
  };
  filesToInstall = [
    "u-boot.itb"
    "idbloader.img"
    "u-boot-rockchip.bin"
  ];
}
