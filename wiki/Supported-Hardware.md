# Supported Hardware

Extra Life scopes each system closure to one System on a Chip (SoC) family (`VARIANT_ID` and `nixosConfigurations` key). The build isolates board quirks in `nixos/devices/devices.toml` and Device Tree Blobs (DTBs). Boot layers apply U-Boot or Unified Extensible Firmware Interface (UEFI) Boot Loader Specification (BLS) entries. Runtime layers apply Advanced Linux Sound Architecture (ALSA) Use Case Manager (UCM2) profiles and `InputPlumber` mappings.

## Active SoC family summary

Four SoC targets build in the flake today. Run `just build-disk <soc>` or `just build-ota <soc>` to build an image or over-the-air (OTA) bundle.

| SoC key (`VARIANT_ID`) | Build commands | Kernel and GPU stack | Bootloader and partition layout | Device count in `devices.toml` |
| --- | --- | --- | --- | --- |
| `x86_64` | `just build-disk x86_64`, `just build-ota x86_64` | Mainline Linux (`bzImage`) with Mesa Graphics Processing Unit (GPU) drivers (`radeonsi`, `iris`, `anv`, `radv`, `virtio`) | `systemd-boot` (`BOOTX64.EFI`) on a two-partition GUID Partition Table (GPT) layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 9 |
| `rk3566` | `just build-disk rk3566`, `just build-ota rk3566` | Mainline Linux (`Image`) with `rockchipdrm` and Mesa `panfrost` | `ubootAnbernicRgxx3` (`u-boot-rockchip.bin` at sector 64) + `extlinux.conf` (`FDTDIR /dtbs`) on GPT (`05-uboot` + `EXTRALIFE` + `STORAGE`) | 11 |
| `sm6115` | `just build-disk sm6115`, `just build-ota sm6115` | Linux 7.2 (`linuxPackages_sm6115` with ROCKNIX `SM6115` patches) and Mesa `freedreno` (`msm`) | `OpenABL` (`rocknix_abl` in Android `abl` partition) + `systemd-boot` (`BOOTAA64.EFI`) BLS entries (`/dtbs/qcom/*.dtb`) on GPT | 4 |
| `aarch64` | `just build-disk aarch64`, `just build-ota aarch64` | Mainline Linux (`Image`) with `virtio-gpu` and Mesa | `systemd-boot` (`BOOTAA64.EFI`) on a two-partition GPT layout (`EXTRALIFE` `vfat` + `STORAGE` `ext4`) | 0 (generic UEFI and `vm-retro`) |

## Currently supported hardware

Every board in a supported SoC family shares one kernel, one Mesa graphics stack, and one `/boot/SYSTEM` SquashFS store image. At boot, `extra-life-board-detect.service` writes `EXTRA_LIFE_BOARD` and `EXTRA_LIFE_PANEL_ORIENTATION` to `/run/extra-life-board.env` before `cage-tty1.service` starts.

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

Extra Life expands hardware support in priority order. Priorities 1 to 6 use mainline Linux kernels and open-source Mesa drivers. Priority 7 (Wave 2) waits on upstream display or audio parity.

| Priority | SoC key | Target devices and cases | Kernel, GPU, and bootloader stack | Known quirks and caveats |
| --- | --- | --- | --- | --- |
| Priority 1 | `rpi4` (`bcm2711`), `rpi5` (`bcm2712`), `rpi02w` (`bcm2710`) | Raspberry Pi 4, 400, 5, and Zero 2 W, plus RetroFlag (GPi Case, NESPi, SUPERPi, MegaPi, PiStation), DeskPi, and Waveshare cases | Mainline Linux (`Image`) with VideoCore Kernel Mode Setting (KMS), Mesa `vc4` and `v3d`, and Raspberry Pi firmware + `config.txt` device tree overlays | Cases require General-Purpose Input/Output (GPIO) safe-shutdown scripts. The 512 MB random-access memory (RAM) limit on Zero 2 W excludes `dolphin_libretro` and `citra_libretro`. |
| Priority 2 | `rk3566` (Tier 2 boards) | Powkiddy X55 and Powkiddy RGB20SX | Mainline Linux (`Image`) with `rockchipdrm`, Mesa `panfrost`, and mainline DTBs (`rk3566-powkiddy-x55.dtb`, `rk3566-powkiddy-rgb20sx.dtb`) | Powkiddy X55 needs a separate `powkiddy-x55-rk3566_defconfig` U-Boot binary and `panel_himax_hx8394`. Powkiddy RGB20SX shares SARADC value `383` with the RGB30 and needs explicit DTB selection. |
| Priority 3 | `h700` | Anbernic RG35XX Plus, 2024, H, SP, Pro, RG40XX H, RG40XX V, RG CubeXX, RG28XX, and RG34XX | Mainline Linux (`Image`) with Mesa `panfrost` and Allwinner `H700` U-Boot | Requires built-in `/lib/firmware/panels/*.panel` Mobile Industry Processor Interface Display Serial Interface (MIPI-DSI) timing firmware and `H700 Gamepad` input mapping. |
| Priority 4 | `sm8250`, `sm8550` | Retroid Pocket 5, Flip 2, Mini, and 6, AYN Odin 2, and AYANEO Pocket S, DMG, and EVO | Mainline Linux (`Image`) with Mesa `freedreno` and `disk-openabl.nix` UEFI/BLS boot | Reuses `qcom-common.nix` (`pd-mapper`, `rmtfs`, and `tqftpserv`) and per-board BLS device tree entries. |
| Priority 5 | `rk3326` | Odroid Go Advance, Odroid Go Super, Anbernic RG351M, RG351V, R36S, R33S, and Powkiddy RGB20S | Mainline Linux (`Image`) with Mesa `panfrost` and Rockchip `RK3326` U-Boot | Requires `odroidgo2_joypad` and `retrogame_joypad` input mappings and respects 1 GB RAM limits. |
| Priority 6 | `x86_64` | Valve Steam Deck, ASUS ROG Ally, Lenovo Legion Go, AYANEO, and AYN Loki handhelds | Mainline Linux (`bzImage`) with Mesa `radeonsi` and `systemd-boot` UEFI | Requires DMI portrait-panel rotation rules and `InputPlumber` composite controller profiles. |
| Priority 7 (Wave 2 deferred) | `rk3588`, `sm6125` | Rockchip `rk3588` (GameForce Ace, Orange Pi 5, Retro Lite CM5, RetrOLED CM5) and Qualcomm `sm6125` dual-screen (Retroid Pocket Duo Lite) | Mainline or patched Linux (`Image`) with Mesa `panfrost` (`rk3588`) or `freedreno` (`sm6125`) | `rk3588` awaits mainline MIPI-DSI and High-Definition Multimedia Interface (HDMI) parity beyond the vendor Linux 6.1 Board Support Package (BSP). `Retroid Pocket Duo Lite` (`sm6125-retroid-pocket-duo-lite.dtb`) requires dual-panel Cage output handling (`duolite-hx83112a` + `duolite-bottom-panel`) and SM6125 SoundWire (`wcd937x`) audio validation. |

## Unsupported hardware (will not support)

Extra Life will not support 32-bit architectures, legacy vendor BSP kernels, closed-source GPU blobs, or unmerged clone board layouts.

| Device or family | SoC and architecture | Technical blocker and rationale |
| --- | --- | --- |
| ClockworkPi GameShell (CPI v3.1) | Allwinner R16 (`sun8i-a33`, 32-bit `armv7l-linux` Cortex-A7, Mali-400 MP2 Utgard `lima`, 1 GB DDR3) | Extra Life targets 64-bit `x86_64-linux` and `aarch64-linux` only. GameShell needs out-of-tree `kd027-lcd` and U-Boot patches and has no 64-bit mainboard upgrade (CPI v3.14 CM4 fits only DevTerm and uConsole). |
| Allwinner `A133` handhelds (Trimui Smart Pro, Trimui Brick, Powkiddy V20, Powkiddy V90S, MagicX Zero 28) | Allwinner `A133` (`aarch64`) | Uses a legacy Linux 4.9 vendor BSP kernel and closed-source PowerVR Rogue (`GE8300`) blobs. Those blobs cannot run mainline Direct Rendering Manager (DRM)/KMS, Mesa, or Cage on NixOS. |
| Out-of-tree `rk3566` clones and Android dual-screen boards (Powkiddy RGB20 Pro, Powkiddy X35S, Anbernic RG DS) | Rockchip `RK3566` (`aarch64`) | Require non-upstream `rocknix,generic-dsi` panel drivers, unmerged U-Boot SARADC patches (`adc_value = 245`), or Android-only dual-screen BSP layouts absent from mainline Linux and U-Boot. |
| Legacy 32-bit ARM and MIPS handhelds and boards (Raspberry Pi 1, 2, Zero, Zero W `armv6l`/`armv7l`, Miyoo Mini and Mini Plus `SigmaStar SSD202D`, Anbernic RG35XX 2023 `Actions ATM7039S`, GCW Zero and RG350 `Ingenic JZ4770`) | 32-bit `armv6l`, `armv7l`, or `mipsel` | Incompatible with 64-bit NixOS closures, mainline KMS and Wayland (`cage` + `ludo -tags wayland`), and the 64-bit Libretro core farm. |
