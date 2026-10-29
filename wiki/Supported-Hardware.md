# Supported Hardware

Extra Life scopes each system closure to one System on a Chip (SoC) family (`VARIANT_ID` and `nixosConfigurations` key). The build isolates board quirks in `nixos/devices/devices.toml` and Device Tree Blobs (DTBs). Boot layers apply U-Boot or Unified Extensible Firmware Interface (UEFI) Boot Loader Specification (BLS) entries. Runtime layers apply Advanced Linux Sound Architecture (ALSA) Use Case Manager (UCM2) profiles and `InputPlumber` mappings.

## Active SoC family summary

Seven SoC targets build in the flake today. Run `just build-disk <soc>` or `just build-ota <soc>` to build an image or over-the-air (OTA) bundle.

| SoC key (`VARIANT_ID`) | Build commands | Kernel and GPU stack | Bootloader and partition layout | Device count in `devices.toml` |
| --- | --- | --- | --- | --- |
| `x86_64` | `just build-disk x86_64`, `just build-ota x86_64` | Mainline Linux (`bzImage`) with Mesa Graphics Processing Unit (GPU) drivers (`radeonsi`, `iris`, `anv`, `radv`, `virtio`) | `systemd-boot` (`BOOTX64.EFI`) on a two-partition GUID Partition Table (GPT) layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 9 |
| `rpi02w` | `just build-disk rpi02w`, `just build-ota rpi02w` | Raspberry Pi Linux 6.12 Long Term Support (LTS) (`linuxPackages_rpi`) with VideoCore Kernel Mode Setting (KMS) and Mesa `vc4` and `v3d` | Raspberry Pi Video Processing Unit (VPU) firmware (`bootcode.bin`, `start*.elf`, or Pi 5 Electrically Erasable Programmable Read-Only Memory (EEPROM)) + `config.txt` and `cmdline.txt` on a hybrid GPT/Master Boot Record (MBR) (`sgdisk -h 1`) two-partition layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 5 |
| `rpi4` | `just build-disk rpi4`, `just build-ota rpi4` | Raspberry Pi Linux 6.12 LTS (`linuxPackages_rpi`) with VideoCore KMS and Mesa `vc4` and `v3d` | Raspberry Pi VPU firmware (`bootcode.bin`, `start*.elf`, or Pi 5 EEPROM) + `config.txt` and `cmdline.txt` on a hybrid GPT/MBR (`sgdisk -h 1`) two-partition layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 4 |
| `rpi5` | `just build-disk rpi5`, `just build-ota rpi5` | Raspberry Pi Linux 6.12 LTS (`linuxPackages_rpi`) with VideoCore KMS and Mesa `vc4` and `v3d` | Raspberry Pi VPU firmware (`bootcode.bin`, `start*.elf`, or Pi 5 EEPROM) + `config.txt` and `cmdline.txt` on a hybrid GPT/MBR (`sgdisk -h 1`) two-partition layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 3 |
| `rk3566` | `just build-disk rk3566`, `just build-ota rk3566` | Mainline Linux (`Image`) with `rockchipdrm` and Mesa `panfrost` | `ubootAnbernicRgxx3` (`u-boot-rockchip.bin` at sector 64) + `extlinux.conf` (`FDTDIR /dtbs`) on GPT (`05-uboot` + `EXTRALIFE` + `STORAGE`) | 11 |
| `sm6115` | `just build-disk sm6115`, `just build-ota sm6115` | Linux 7.2 (`linuxPackages_sm6115` with ROCKNIX `SM6115` patches) and Mesa `freedreno` (`msm`) | `OpenABL` (`rocknix_abl` in Android `abl` partition) + `systemd-boot` (`BOOTAA64.EFI`) BLS entries (`/dtbs/qcom/*.dtb`) on GPT | 4 |
| `aarch64` | `just build-disk aarch64`, `just build-ota aarch64` | Mainline Linux (`Image`) with `virtio-gpu` and Mesa | `systemd-boot` (`BOOTAA64.EFI`) on a two-partition GPT layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 0 (generic UEFI and `vm-retro`) |

## Currently supported hardware

Every board in a supported SoC family shares one kernel, one Mesa graphics stack, and one `/boot/SYSTEM` SquashFS store image. Extra Life prefers the current NixOS LTS kernel (`pkgs.linuxPackages`) and open-source Mesa drivers where possible. When a device's DTBs, display drivers, Board Support Package (BSP), or binary blobs require a specific kernel version, the SoC closure packages a compatible kernel in `pkgs/kernels/`. That kernel can come from `nixpkgs`, `pkgs.unstable`, an older NixOS revision, or a vendor BSP tree. At boot, `extra-life-board-detect.service` writes `EXTRA_LIFE_BOARD` and `EXTRA_LIFE_PANEL_ORIENTATION` to `/run/extra-life-board.env` before `cage-tty1.service` starts.

### `x86_64` (`AMD64` PCs, virtual machines, and GPD handhelds)

The `x86_64` closure runs on 64-bit personal computers (PCs), QEMU virtual machines (VMs), and eight GPD handheld models.

- **Board detection**: `extra-life-board-detect` reads `/sys/class/dmi/id/{sys_vendor,product_name,board_vendor,board_name}` Desktop Management Interface (DMI) strings. On early 7Y30 GPD WIN 2 Basic Input/Output System (BIOS) releases with `"Default string"`, it checks Universal Serial Bus (USB) devices for `0079:18d4`.
- **Display and orientation**: GPD WIN 2, WIN Max (2020 and 2021), WIN 3, and WIN Mini (2023) rotate portrait panels with `panel_orientation = "270"`. Generic PCs, WIN Max 2, WIN 4, WIN 5, and WIN Mini (2024) use native landscape panels with `panel_orientation = "normal"`.
- **Controls and audio**: Internal XInput controllers bind to `xpad` (`0079:18d4` and `045e:028e`), and `InputPlumber` loads `50-gpd_win*.yaml` profiles. Audio uses Intel and AMD High Definition (HD) Audio (`snd_hda_intel`) and Sound Open Firmware (SOF) (`snd_sof_pci_intel_icl`, `snd_sof_pci_intel_tgl`).
- **Quirks and caveats**: A `udev` rule sets `LIBINPUT_CALIBRATION_MATRIX="0 1 0 -1 0 1"` on `Goodix Capacitive TouchScreen` for rotated panels. On GPD WIN Max 2020 (`G1619-01`), an `extraHwdb` rule sets `KEYBOARD_KEY_a0=!mute` to block phantom mute events.

| Device ID | Retail name | DMI vendor and product match | USB fallback | Panel orientation | Touchscreen matrix and quirks |
| --- | --- | --- | --- | --- | --- |
| `x86_64-generic` | Generic x86_64 PC / UEFI | Default fallback | None | `normal` | Standard UEFI PC and `vm-retro` guest |
| `gpd-win-2` | GPD WIN 2 | `GPD` / `WIN2` | `0079:18d4` | `270` | `0 1 0 -1 0 1` (matches `WIN2` and `"Default string"` BIOS) |
| `gpd-win-max` | GPD WIN Max (2020 / 2021) | `GPD` / `G1619-01`, `G1619-02`, `G1619-03` | None | `270` | `0 1 0 -1 0 1`, plus `KEYBOARD_KEY_a0=!mute` on `G1619-01` |
| `gpd-win-max-2` | GPD WIN Max 2 | `GPD` / `G1619-04`, `G1619-05` | None | `normal` | Native landscape panel |
| `gpd-win-3` | GPD WIN 3 | `GPD` / `G1618-03` | None | `270` | `0 1 0 -1 0 1` |
| `gpd-win-4` | GPD WIN 4 | `GPD` / `G1618-04` | None | `normal` | Native landscape panel |
| `gpd-win-5` | GPD WIN 5 | `GPD` / `G1618-05` | None | `normal` | Native landscape panel |
| `gpd-win-mini-2023` | GPD WIN Mini (2023) | `GPD` / `G1617-01` | None | `270` | `0 1 0 -1 0 1` |
| `gpd-win-mini-2024` | GPD WIN Mini (2024) | `GPD` / `G1617-02`, `G1617-02-L` | None | `normal` | Native landscape panel |

### `rpi02w`, `rpi4`, and `rpi5` (Broadcom Raspberry Pi boards and retro cases)

The `rpi02w` (`bcm2710`), `rpi4` (`bcm2711`), and `rpi5` (`bcm2712`) closures support 12 Raspberry Pi boards and 9 retro enclosures.

- **Direct VPU firmware boot**: `disk-rpi.nix` populates the `EXTRALIFE` `vfat` partition with `bootcode.bin`, `start*.elf`, `fixup*.dat`, `bcm27*.dtb`, `overlays/`, `KERNEL`, `INITRD`, and `SYSTEM`. Raspberry Pi 5 boards boot from the on-board Serial Peripheral Interface (SPI) EEPROM and read `config.txt` and `cmdline.txt` from `EXTRALIFE`. `config.txt` includes `extralife-case.txt` in the `[all]` section, and `cmdline.txt` passes `init=/nix/store/current-system/init` with the kernel parameters.
- **Hybrid GPT/MBR partition layout**: `disk-rpi.nix` runs `sgdisk -h 1` after image creation to place `10-boot` (`EXTRALIFE`) in MBR slot 1. The `BCM2837` mask Read-Only Memory (ROM) on `rpi02w` and Raspberry Pi 3 boards requires an MBR entry to locate `bootcode.bin`.
- **Kernel, GPU, and CMA allocation**: All three closures run Raspberry Pi Linux 6.12 LTS (`linuxPackages_rpi`) with `vc4-kms-v3d`, `vc4-kms-v3d-pi4`, or `vc4-kms-v3d-pi5`. `rpi02w.nix` sets Contiguous Memory Allocator (CMA) allocation to `cma=128M` for 512 MB and 1 GB boards, whereas `rpi4` and `rpi5` set `cma=256M`.
- **Retro cases and runtime service**: Users can set `extraLife.case` at build time or uncomment a profile in `/boot/extralife-case.txt` without a rebuild. At boot, `extra-life-case.service` reads `/boot/case.txt`, `/storage/.config/extra-life-case`, or `config.extraLife.case`. For `deskpi-pro` (`ch341` on `/dev/ttyUSB0`) and `argon-one` (`i2c-dev` on `/dev/i2c-1` address `0x1a`), it polls `thermal_zone0` every 10 seconds to control the fan. On shutdown, `extra-life-case.service` stops the fan or cuts power.

#### Supported Raspberry Pi boards

| Device ID | Retail name | SoC key | Device tree model (`dt_model`) | First `dt_compatibles` entry | DTB (`dtb`) | Notes / caveats |
| --- | --- | --- | --- | --- | --- | --- |
| `rpi-zero-2-w` | Raspberry Pi Zero 2 W | `rpi02w` | None (matches `dt_compatibles`) | `raspberrypi,model-zero-2-w` | `broadcom/bcm2710-rpi-zero-2-w.dtb` | 512 MB random-access memory (RAM), `cma=128M`, `gpu_mem=64`, and MBR slot 1 |
| `rpi-3-b` | Raspberry Pi 3 Model B | `rpi02w` | None (matches `dt_compatibles`) | `raspberrypi,3-model-b` | `broadcom/bcm2710-rpi-3-b.dtb` | 1 GB RAM, `cma=128M`, `gpu_mem=64`, and MBR slot 1 |
| `rpi-3-b-plus` | Raspberry Pi 3 Model B+ | `rpi02w` | None (matches `dt_compatibles`) | `raspberrypi,3-model-b-plus` | `broadcom/bcm2710-rpi-3-b-plus.dtb` | 1 GB RAM, `cma=128M`, `gpu_mem=64`, and MBR slot 1 |
| `rpi-3-a-plus` | Raspberry Pi 3 Model A+ | `rpi02w` | None (matches `dt_compatibles`) | `raspberrypi,3-model-a-plus` | `broadcom/bcm2710-rpi-3-a-plus.dtb` | 512 MB RAM, `cma=128M`, `gpu_mem=64`, and MBR slot 1 |
| `rpi-cm3` | Raspberry Pi Compute Module 3 / 3+ | `rpi02w` | None (matches `dt_compatibles`) | `raspberrypi,3-compute-module` | `broadcom/bcm2710-rpi-cm3.dtb` | 1 GB RAM, `cma=128M`, `gpu_mem=64`, and MBR slot 1 |
| `rpi-4-b` | Raspberry Pi 4 Model B | `rpi4` | None (matches `dt_compatibles`) | `raspberrypi,4-model-b` | `broadcom/bcm2711-rpi-4-b.dtb` | `vc4-kms-v3d-pi4`, `cma=256M`, `max_framebuffers=2`, and `arm_boost=1` |
| `rpi-400` | Raspberry Pi 400 | `rpi4` | None (matches `dt_compatibles`) | `raspberrypi,400` | `broadcom/bcm2711-rpi-400.dtb` | Keyboard form factor with `vc4-kms-v3d-pi4` and `cma=256M` |
| `rpi-cm4` | Raspberry Pi Compute Module 4 | `rpi4` | None (matches `dt_compatibles`) | `raspberrypi,4-compute-module` | `broadcom/bcm2711-rpi-cm4.dtb` | Sets `otg_mode=1` under `[cm4]` in `config.txt` with `cma=256M` |
| `rpi-cm4s` | Raspberry Pi Compute Module 4S | `rpi4` | None (matches `dt_compatibles`) | `raspberrypi,4-compute-module-s` | `broadcom/bcm2711-rpi-cm4s.dtb` | Small Outline Dual In-line Memory Module (SODIMM) board with `vc4-kms-v3d-pi4` and `cma=256M` |
| `rpi-5-b` | Raspberry Pi 5 | `rpi5` | None (matches `dt_compatibles`) | `raspberrypi,5-model-b` | `broadcom/bcm2712-rpi-5-b.dtb` | RP1 southbridge (`rp1`, `rp1_pio`, `pinctrl_rp1`), `vc4-kms-v3d-pi5`, and `cma=256M` |
| `rpi-500` | Raspberry Pi 500 | `rpi5` | None (matches `dt_compatibles`) | `raspberrypi,500` | `broadcom/bcm2712-rpi-500.dtb` | Keyboard form factor with RP1 southbridge, `vc4-kms-v3d-pi5`, and `cma=256M` |
| `rpi-cm5` | Raspberry Pi Compute Module 5 | `rpi5` | None (matches `dt_compatibles`) | `raspberrypi,5-compute-module` | `broadcom/bcm2712-rpi-cm5-cm5io.dtb` | Uses the Input/Output (IO) board DTB with RP1 southbridge, `vc4-kms-v3d-pi5`, and `cma=256M` |

#### Supported Raspberry Pi retro cases

| Case ID | Retail name | Compatible SoC keys | `extraLife.case` value | Overlays, GPIO, and runtime services |
| --- | --- | --- | --- | --- |
| `retroflag-nespi` | RetroFlag NESPi Case+ / NESPi 4 Case | `rpi02w`, `rpi4` | `retroflag` | Sets `enable_uart=1`, `gpio-poweroff,gpiopin=4,active_low=1,input=1`, and `gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up` in `config.txt` or `/boot/extralife-case.txt` |
| `retroflag-superpi` | RetroFlag SUPERPi Case | `rpi02w`, `rpi4` | `retroflag` | Sets `enable_uart=1`, `gpio-poweroff,gpiopin=4,active_low=1,input=1`, and `gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up` in `config.txt` or `/boot/extralife-case.txt` |
| `retroflag-megapi` | RetroFlag MegaPi Case | `rpi02w` | `retroflag` | Sets `enable_uart=1`, `gpio-poweroff,gpiopin=4,active_low=1,input=1`, and `gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up` in `config.txt` or `/boot/extralife-case.txt` |
| `retroflag-pistation` | RetroFlag PiStation Case | `rpi4` | `retroflag` | Sets `enable_uart=1`, `gpio-poweroff,gpiopin=4,active_low=1,input=1`, and `gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up` in `config.txt` or `/boot/extralife-case.txt` |
| `retroflag-gpi-case` | RetroFlag GPi Case v1 | `rpi02w` | `gpi-case` | Sets `dpi24` (320x240 Display Parallel Interface (DPI) Liquid-Crystal Display (LCD) timings), `pwm-audio-pi-zero`, `gpio-poweroff` on General-Purpose Input/Output (GPIO) 26, and `gpio-shutdown` on GPIO 27 |
| `retroflag-gpi-case-2` | RetroFlag GPi Case 2 | `rpi4` | `gpi-case-2` | Sets `dpi24` (640x480 DPI LCD timings), `audremap,pins_18_19`, `gpio-poweroff` on GPIO 26, and `gpio-shutdown` on GPIO 27 |
| `retroflag-gpi-case-2w` | RetroFlag GPi Case 2W | `rpi02w` | `gpi-case-2w` | Sets `dpi24` (640x480 DPI LCD timings), `pwm-audio-pi-zero`, `gpio-poweroff` on GPIO 26, and `gpio-shutdown` on GPIO 27 |
| `deskpi-pro` | DeskPi Pro v1 / v2 | `rpi4` | `deskpi-pro` | Sets `dwc2,dr_mode=host` and `enable_uart=1`. When `/boot/case.txt` or `extraLife.case` is `deskpi-pro`, `extra-life-case.service` controls `ch341` `/dev/ttyUSB0` Pulse-Width Modulation (PWM) speeds and sends `power_off` on stop |
| `argon-one` | Argon ONE v2 / v3 | `rpi4`, `rpi5` | `argon-one` | Sets `dtparam=i2c_arm=on`, `enable_uart=1`, and `gpio-shutdown,gpio_pin=4,active_low=0,gpio_pull=down`. When `/boot/case.txt` or `extraLife.case` is `argon-one`, `extra-life-case.service` controls Inter-Integrated Circuit (I2C) `/dev/i2c-1` (`0x1a`) speeds |

### `rk3566` (Rockchip RK3566 handhelds)

The `rk3566` closure supports 11 Anbernic and Powkiddy handhelds from one image.

- **Bootloader and auto-detection**: `disk-rk3566.nix` writes `ubootAnbernicRgxx3` (`anbernic-rgxx3-rk3566_defconfig`) at sector 64. The U-Boot Secondary Program Loader (SPL) reads Successive Approximation Register Analogue-to-Digital Converter (SARADC) channel 1 (`saradc@fe720000`). It also probes `mmc0` embedded MultiMediaCard (eMMC) storage to select `rockchip/rk3566-*.dtb` from `/dtbs`.
- **Display and orientation**: U-Boot Flattened Device Tree (FDT) fixup probes `panel_newvision_nv3051d` and `panel_sitronix_st7703` panels on the RG353 family. The RG503 drives an Organic Light-Emitting Diode (OLED) panel (`panel_magnachip_d53e6ea8966`) over `spi_gpio`. The RG ARC-D and RG ARC-S use `panel_sitronix_st7701` with `90` rotation, and the RGB10MAX3 uses `270` rotation.
- **Controls and audio**: `InputPlumber` loads `50-rk3566-handheld.yaml` to merge `adc-joystick`, `gpio-keys-control`, and `adc-keys`. It maps `BTN_C` and `BTN_Z` to `RightStick` and `LeftStick` on the 6-button RG ARC. Audio uses `snd_soc_rk817` with `rk817_ext` and `rk817_int` UCM2 profiles.
- **Quirks and caveats**: The RG353M shares `rockchip/rk3566-anbernic-rg353p.dtb` with the RG353P. U-Boot rewrites `/proc/device-tree/model` to `"Anbernic RG353M"` and prepends `"anbernic,rg353m"` to `/proc/device-tree/compatible`.

| Device ID | Retail name | Device tree model (`dt_model`) | First `dt_compatibles` entry | Mainline DTB (`dtb`) | Panel orientation |
| --- | --- | --- | --- | --- | --- |
| `anbernic-rg353m` | Anbernic RG353M | `Anbernic RG353M` | `anbernic,rg353m` | `rockchip/rk3566-anbernic-rg353p.dtb` | `normal` |
| `anbernic-rg353p` | Anbernic RG353P | `Anbernic RG353P` | `anbernic,rg353p` | `rockchip/rk3566-anbernic-rg353p.dtb` | `normal` |
| `anbernic-rg353ps` | Anbernic RG353PS | `Anbernic RG353PS` | `anbernic,rg353ps` | `rockchip/rk3566-anbernic-rg353ps.dtb` | `normal` |
| `anbernic-rg353v` | Anbernic RG353V | `Anbernic RG353V` | `anbernic,rg353v` | `rockchip/rk3566-anbernic-rg353v.dtb` | `normal` |
| `anbernic-rg353vs` | Anbernic RG353VS | `Anbernic RG353VS` | `anbernic,rg353vs` | `rockchip/rk3566-anbernic-rg353vs.dtb` | `normal` |
| `anbernic-rg503` | Anbernic RG503 | `Anbernic RG503` | `anbernic,rg503` | `rockchip/rk3566-anbernic-rg503.dtb` | `normal` |
| `anbernic-rg-arc-d` | Anbernic RG ARC-D | `Anbernic RG ARC-D` | `anbernic,rg-arc-d` | `rockchip/rk3566-anbernic-rg-arc-d.dtb` | `90` |
| `anbernic-rg-arc-s` | Anbernic RG ARC-S | `Anbernic RG ARC-S` | `anbernic,rg-arc-s` | `rockchip/rk3566-anbernic-rg-arc-s.dtb` | `90` |
| `powkiddy-rgb10max3` | Powkiddy RGB10MAX3 | `Powkiddy RGB10MAX3` | `powkiddy,rgb10max3` | `rockchip/rk3566-powkiddy-rgb10max3.dtb` | `270` |
| `powkiddy-rgb30` | Powkiddy RGB30 | `Powkiddy RGB30` | `powkiddy,rgb30` | `rockchip/rk3566-powkiddy-rgb30.dtb` | `normal` |
| `powkiddy-rk2023` | Powkiddy RK2023 | `Powkiddy RK2023` | `powkiddy,rk2023` | `rockchip/rk3566-powkiddy-rk2023.dtb` | `normal` |

### `sm6115` (Qualcomm Snapdragon 662 handhelds)

The `sm6115` closure supports four Mangmi handheld variants on the Qualcomm Snapdragon 662 platform.

- **Kernel and bootloader**: `linuxPackages_sm6115` builds Linux 7.2 with the ROCKNIX `SM6115` patch set. `OpenABL` (`rocknix_abl` in the Android `abl` partition) starts `systemd-boot` (`BOOTAA64.EFI`) and reads BLS entries in `/loader/entries/extra-life-*.conf`.
- **Display and orientation**: The Air X revisions use `mangmi,td4310` (MQ65), `mangmi,hx83112a` (MQ66), and `mangmi,bm5460bb1` (MQ66B) with `270` rotation. The Mangmi Air Y uses a `mangmi,gh7005` panel with `normal` orientation.
- **Controls**: The `mangmi` driver reads the 4 Mbps Universal Asynchronous Receiver-Transmitter (UART) joypad. `InputPlumber` loads `40-mangmi_airx.yaml` and `39-mangmi_airy.yaml`.
- **Audio, wireless, and Qualcomm services**: Audio uses `AW88261` and `ES8326` with `MangmiAirX` and `MangmiAirY` UCM2 profiles and the `S16LE` WirePlumber rule. Wireless uses `WCN3950` (`ath10k_snoc` Wi-Fi and `btqca` Bluetooth) with `qrtr-ns`, `pd-mapper`, `rmtfs`, and `tqftpserv`.

| Device ID | Retail name | Device tree model (`dt_model`) | First `dt_compatibles` entry | DTB (`dtb`) | Panel driver and orientation |
| --- | --- | --- | --- | --- | --- |
| `mangmi-air-x-mq65` | Mangmi Air X (MQ65) | `MANGMI Air X MQ65` | `mangmi,sm6115-air-x-mq65` | `qcom/sm6115-mangmi-air-x-mq65.dtb` | `mangmi,td4310`, `270` |
| `mangmi-air-x-mq66` | Mangmi Air X (MQ66) | `MANGMI Air X MQ66` | `mangmi,sm6115-air-x-mq66` | `qcom/sm6115-mangmi-air-x-mq66.dtb` | `mangmi,hx83112a`, `270` |
| `mangmi-air-x-mq66b` | Mangmi Air X (MQ66B) | `MANGMI Air X MQ66B` | `mangmi,sm6115-air-x-mq66b` | `qcom/sm6115-mangmi-air-x-mq66b.dtb` | `mangmi,bm5460bb1`, `270` |
| `mangmi-air-y` | Mangmi Air Y | `MANGMI Air Y` | `mangmi,sm6115-air-y` | `qcom/sm6115-mangmi-air-y.dtb` | `mangmi,gh7005`, `normal` |

### `aarch64` (Generic ARM64 UEFI and `vm-retro`)

The `aarch64` closure targets generic 64-bit ARM UEFI systems and the `vm-retro` QEMU `virt` machine. It runs on `aarch64-linux` (`kvm`) and on Apple Silicon `aarch64-darwin` (`hvf` with `linux-builder`).

## Hardware roadmap

Extra Life expands hardware support in priority order. Each SoC closure uses the NixOS LTS kernel when possible or packages a patched or vendor BSP kernel in `pkgs/kernels/`.

| Priority | SoC key | Target devices and cases | Kernel, GPU, and bootloader stack | Known quirks and caveats |
| --- | --- | --- | --- | --- |
| Priority 1 | `rk3566` (Tier 2 boards) | Powkiddy X55, Powkiddy RGB20SX, Powkiddy RGB20 Pro, and Powkiddy X35S | Mainline or ROCKNIX-patched Linux (`Image`) with `rockchipdrm`, Mesa `panfrost`, and `rk3566-powkiddy-*.dtb` | `X55` needs `powkiddy-x55-rk3566_defconfig` U-Boot and `panel_himax_hx8394`. `RGB20SX` needs explicit DTB selection because it shares SARADC `383` with the RGB30. `RGB20 Pro` and `X35S` need ROCKNIX `RK3566` kernel and U-Boot patches (`rocknix,generic-dsi` panel driver and SARADC `245`). |
| Priority 2 | `h700` | Anbernic RG35XX Plus, 2024, H, SP, Pro, RG40XX H, RG40XX V, RG CubeXX, RG28XX, and RG34XX | Mainline Linux (`Image`) with Mesa `panfrost` and Allwinner `H700` U-Boot | Requires built-in `/lib/firmware/panels/*.panel` Mobile Industry Processor Interface Display Serial Interface (MIPI-DSI) timing firmware and `H700 Gamepad` input mapping. |
| Priority 3 | `sm8250`, `sm8550` | Retroid Pocket 5, Flip 2, Mini, and 6, AYN Odin 2, and AYANEO Pocket S, DMG, and EVO | Mainline Linux (`Image`) with Mesa `freedreno` and `disk-openabl.nix` UEFI/BLS boot | Reuses `qcom-common.nix` (`pd-mapper`, `rmtfs`, and `tqftpserv`) and per-board BLS device tree entries. |
| Priority 4 | `rk3326` | Odroid Go Advance, Odroid Go Super, Anbernic RG351M, RG351V, R36S, R33S, and Powkiddy RGB20S | Mainline Linux (`Image`) with Mesa `panfrost` and Rockchip `RK3326` U-Boot | Requires `odroidgo2_joypad` and `retrogame_joypad` input mappings and respects 1 GB RAM limits. |
| Priority 5 | `x86_64` | Valve Steam Deck, ASUS ROG Ally, Lenovo Legion Go, AYANEO, and AYN Loki handhelds | Mainline Linux (`bzImage`) with Mesa `radeonsi` and `systemd-boot` UEFI | Requires DMI portrait-panel rotation rules and `InputPlumber` composite controller profiles. |
| Priority 6 | `rk3588`, `sm6125` | Rockchip `rk3588` (GameForce Ace, Orange Pi 5, Retro Lite CM5, RetrOLED CM5) and Qualcomm `sm6125` dual-screen (Retroid Pocket Duo Lite) | Pinned Linux 6.1 vendor BSP (`pkgs/kernels/rk3588.nix`) with Mesa `panfrost`, or patched Linux (`Image`) with Mesa `freedreno` (`sm6125`) | `rk3588` can use a pinned Linux 6.1 vendor BSP kernel in `pkgs/kernels/rk3588.nix` with Mesa `panfrost` until mainline MIPI-DSI and High-Definition Multimedia Interface (HDMI) parity matures. `Retroid Pocket Duo Lite` (`sm6125-retroid-pocket-duo-lite.dtb`) needs dual-panel Cage output handling (`duolite-hx83112a` + `duolite-bottom-panel`) and SM6125 SoundWire (`wcd937x`) audio validation. |
| Priority 7 (low priority) | `sun8i-a33`, `bcm2836`, `sun8i-h3`, `rk3288` (`armv7l-linux`) | ClockworkPi GameShell (CPI v3.1), Raspberry Pi 2 Model B, Allwinner H3 and H2+ handhelds (Retrostone), and Rockchip RK3288 boards | Mainline or patched 32-bit Linux (`zImage`) with Mesa `lima` (`sun8i-a33`, `sun8i-h3`), `vc4` (`bcm2836`), or `panfrost` (`rk3288`) and U-Boot or Raspberry Pi firmware | This tier is last on the roadmap for three reasons. `cache.nixos.org` has no `armv7l-linux` binary cache, so `binfmt` or `pkgsCross` builds must compile the kernel, `llvm`, `mesa`, `systemd`, `pipewire`, `samba`, `cage`, `ludo`, and cores from source. The build must exclude 64-bit-only Libretro cores (`dolphin_libretro`, `citra_libretro`, `mednafen_saturn_libretro`, `flycast_libretro`, `pcsx2_libretro`), and `mupen64plus_next_libretro` requires `WITH_DYNAREC=arm`. ClockworkPi GameShell needs out-of-tree `clockworkpi-cpi3` U-Boot, `sun8i-r16-clockworkpi-cpi3.dts`, and `kd027-lcd` and `ocp8178-backlight` kernel patches. |

## Unsupported hardware (will not support)

Extra Life excludes hardware with unsupported instruction sets (`armv6l`, `mipsel`), less than 512 MB RAM, or no OpenGL or OpenGL for Embedded Systems (GLES) GPU. It also excludes closed-source GPU blobs without 64-bit Linux Direct Rendering Manager (DRM)/KMS and Generic Buffer Management (GBM)/Embedded-System Graphics Library (EGL) support, and hardware without Linux kernel sources.

| Device or family | SoC and architecture | Technical blocker and rationale |
| --- | --- | --- |
| GPU-less or ultra-low-RAM 32-bit handhelds (Miyoo Mini and Mini Plus `SigmaStar SSD202D`, Anbernic RG35XX 2023 `Actions ATM7039S`) | `SigmaStar SSD202D` (`armv7l`), `Actions ATM7039S` (`armv7l`) | `SSD202D` has only 128 MB RAM and no 3D OpenGL/GLES GPU (`fbdev` only, so `cage` and `ludo` cannot run). `ATM7039S` is locked to a Linux 3.4 kernel without DRM/KMS or Mesa drivers. |
| ARMv6 and MIPS handhelds and boards (Raspberry Pi 1, Zero, and Zero W `BCM2835` `armv6l`, Anbernic RG350 and GCW Zero `Ingenic JZ4770` `mipsel`) | 32-bit `armv6l-linux` or `mipsel-linux` | Use `armv6l-linux` or `mipsel-linux` instruction sets that lack Go, Wayland kiosk, and Libretro core farm support in NixOS. |
| Allwinner `A133` handhelds (Trimui Smart Pro, Trimui Brick, Powkiddy V20, Powkiddy V90S, MagicX Zero 28) | Allwinner `A133` (`aarch64`) | Ships with a Linux 4.9 BSP and closed-source PowerVR Rogue (`GE8300`) blobs that lack a working 64-bit Linux DRM/KMS and GBM/EGL driver stack for `cage` (`wlroots`) on NixOS. |
| Android-only dual-screen handhelds without Linux BSPs (Anbernic RG DS) | Android-only dual-screen SoCs (`aarch64`) | Ships without Linux kernel sources, device trees, or DRM/KMS panel drivers for the dual-screen hardware. |
