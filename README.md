<h1 align="center">
  <img src="assets/logo.svg" alt="Extra Life Logo" width="256" />
  <br />
  Extra Life
</h1>

<p align="center"><b>Give Extra Life to Classic Games and Hardware 🕹</b></p>

Extra Life (`extra-life`, <https://extralife.wimpys.world>) is a retro game appliance on NixOS that boots directly into Ludo on the Cage Wayland compositor. It gives extra life to classic games and hardware across `x86_64-linux` personal computers (PCs), Raspberry Pi boards, and ARM handhelds. The appliance has no desktop environment, no text consoles, no RetroArch menus, and no runtime Nix binaries, databases, or evaluators.

```bash
# Run the appliance in a local QEMU virtual machine
nix run .#vm-retro
```

## Product principles

Four product principles govern every decision in Extra Life.

| Principle | Rule | Impact |
| --- | --- | --- |
| Pure appliance | The system boots straight into `cage` and runs `ludo -ludos` on native Wayland. | You get a console experience with no desktop escape hatch, no text console prompts, and no RetroArch interface. |
| Invisible Nix | Continuous Integration (CI) runs Nix at build time only. The appliance sets `nix.enable = false` and updates from Cloudflare R2 through `/storage/.update/` in `initrd`. | You flash an image, copy read-only memory (ROM) files, and apply over-the-air (OTA) updates with zero runtime Nix binaries, databases, or evaluators. |
| Opinionated emulation | The image ships 33 curated Libretro cores in a single `cores_dir` directory. | Every supported playlist in Ludo (`CoreForPlaylist`) runs out of the box without manual core downloads. |
| Universal hardware reach | One flake builds `x86_64-linux` PC and virtual machine (VM) images alongside `aarch64-linux` board and handheld images, and supports `aarch64-darwin` hosts. | The same configuration runs on QEMU across Linux and Apple Silicon macOS, PC hardware, Raspberry Pi boards, and ARM handhelds. |

## Quick start

### Run in a virtual machine

Start the `vm-retro` target with `just` or Nix to build and boot either the writable appliance disk image or the live ISO locally.

```bash
# Build the UEFI GPT disk image, seed .vm/disk.qcow2 (64 GB), and boot it
just boot-disk

# Or build the live ISO and boot it
just boot-iso
```

The VM runs on `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin` (Apple Silicon macOS). On Linux, QEMU uses Kernel-based Virtual Machine (KVM), Unified Extensible Firmware Interface (UEFI) firmware, `virtio-vga-gl` or `virtio-gpu-gl-pci` OpenGL, GTK display, and PipeWire audio. On Apple Silicon macOS, `just boot-disk` and `just boot-iso` build the `aarch64-linux` image through a `linux-builder` such as Determinate Nix. QEMU then boots the image with Hypervisor.framework (`hvf`), the Cocoa display (`-display cocoa`), and CoreAudio. Pass `--usb-device VID:PID` to forward Universal Serial Bus (USB) gamepads on macOS or Linux. The runner keeps persistent state and `/storage/Retro` in `.vm/` and forwards host port `2222` to Secure Shell (SSH) port `22` on the guest.

```bash
# Copy ROM files into the running virtual machine over SSH
rsync -avP -e "ssh -p 2222" ./roms/ ludo@localhost:/storage/Retro/roms/
```

### Build appliance images

Build bootable disk or installer images for the host architecture (`x86_64-linux` or `aarch64-linux`), or select a specific NixOS configuration.

```bash
# Build the disk image or installer ISO for the current architecture
just build-disk
just build-iso

# Build specific x86_64-linux or aarch64-linux images directly
nix build .#nixosConfigurations.x86_64-appliance.config.system.build.diskImage
nix build .#nixosConfigurations.aarch64-appliance.config.system.build.diskImage
```

For full design details, read the [Extra Life architecture guide](docs/architecture.md).

## Supported systems

Extra Life ships 33 Libretro cores that match the `CoreForPlaylist` map in Ludo. Every core runs on both `x86_64-linux` and `aarch64-linux`, except where the table notes a platform rule.

| Manufacturer or group | Systems | Libretro cores | Platform notes |
| --- | --- | --- | --- |
| Arcade and engines | FBNeo - Arcade Games, Cave Story, ChaiLove | `fbneo_libretro`, `nxengine_libretro`, `chailove_libretro` | All targets |
| Atari | 2600, 5200, 7800, Jaguar, Lynx, ST | `stella2014_libretro`, `atari800_libretro`, `prosystem_libretro`, `virtualjaguar_libretro`, `handy_libretro`, `hatari_libretro` | All targets |
| Bandai | WonderSwan, WonderSwan Color | `mednafen_wswan_libretro` | All targets |
| Coleco, Microsoft, and Spectravideo | ColecoVision, MSX, MSX2, SVI-318 - SVI-328 | `bluemsx_libretro` | All targets |
| GCE, Magnavox, and Philips | Vectrex, Odyssey2, Videopac+ | `vecx_libretro`, `o2em_libretro` | All targets |
| NEC | PC Engine - TurboGrafx 16, PC Engine CD - TurboGrafx-CD, PC Engine SuperGrafx, PC-FX | `mednafen_pce_libretro`, `mednafen_pcfx_libretro` | All targets |
| Nintendo consoles | Entertainment System, Family Computer Disk System, Super Nintendo, Satellaview, Sufami Turbo, Nintendo 64, GameCube, Virtual Boy | `fceumm_libretro`, `snes9x_libretro`, `mupen64plus_next_libretro`, `dolphin_libretro`, `mednafen_vb_libretro` | `dolphin_libretro` runs on `x86_64-linux` and capable `aarch64-linux` targets |
| Nintendo handhelds | Game Boy, Game Boy Color, Game Boy Advance, Pokemon Mini, Nintendo DS, Nintendo 3DS | `gambatte_libretro`, `mgba_libretro`, `pokemini_libretro`, `melonds_libretro`, `citra_libretro` | `citra_libretro` runs on `x86_64-linux` and capable `aarch64-linux` targets |
| Sega | SG-1000, Master System - Mark III, Mega Drive - Genesis, Mega-CD - Sega CD, 32X, PICO, Game Gear, Saturn, Dreamcast | `genesis_plus_gx_libretro`, `picodrive_libretro`, `mednafen_saturn_libretro`, `flycast_libretro` | All targets |
| SNK | Neo Geo Pocket, Neo Geo Pocket Color | `mednafen_ngp_libretro` | All targets |
| Sony | PlayStation, PlayStation 2, PlayStation Portable | `swanstation_libretro`, `pcsx_rearmed_libretro`, `pcsx2_libretro`, `ppsspp_libretro` | PlayStation uses `swanstation_libretro` on `x86_64-linux` and `pcsx_rearmed_libretro` on `aarch64-linux`. `pcsx2_libretro` runs on `x86_64-linux` only. |

## How the appliance works

### Kiosk display and audio stack

At boot, systemd starts PipeWire, ConnMan, BlueZ, Samba, and OpenSSH, then launches `cage` on the primary display. Extra Life applies `teardown-order.patch` to Cage so that Wayland clients and wlroots resources close cleanly on reboot or poweroff. Cage starts `ludo -ludos` (`v0.22.5`, compiled with `-tags wayland`) as user `ludo` with user identifier (UID) 1000.

### Declarative `-ludos` services

In `-ludos` mode, the Ludo settings menu controls Wi-Fi, Bluetooth, SSH, Samba file shares, and system power. Ludo writes service marker files in `/storage/.cache/services/{sshd,samba,bluez}.conf` and Wi-Fi credentials in `/storage/.cache/connman/<service>/settings`. Systemd drop-in units check `ConditionPathExists=/storage/.cache/services/*.conf` so that service choices persist across reboots while `/etc` stays immutable. Polkit rules authorise user `ludo` to manage these services, ConnMan, and power actions without a password.

### Storage and partition layout

Appliance images use a two-partition GUID Partition Table (GPT) layout that separates immutable boot and system artefacts from mutable user data.

| Partition | Filesystem and label | Mount point | Contents and behaviour |
| --- | --- | --- | --- |
| Partition 1 | `vfat` (labelled `EXTRALIFE`) | `/boot` | Holds the bootloader (UEFI `BOOTX64.EFI` or `BOOTAA64.EFI`, U-Boot, or Raspberry Pi firmware) and `.dtb` files. Also stores `KERNEL`, `INITRD`, `SYSTEM` (read-only `zstd` SquashFS mounted at `/nix/store`), and `.prev` rollback files. |
| Partition 2 | `ext4` (labelled `STORAGE`) | `/storage` | Expands automatically on first boot and holds `/storage/Retro/{playlists,roms,savefiles,savestates,screenshots,system,thumbnails}`, `/storage/.cache/{services,connman}`, `/storage/.config`, and `/storage/.update`. |

| Path | Contents |
| --- | --- |
| `/storage/Retro/roms` | User ROM sets that are organised by system name |
| `/storage/Retro/system` | Basic Input/Output System (BIOS) files and firmware that specific cores require |
| `/storage/Retro/playlists` | Generated playlist files |
| `/storage/Retro/savefiles` | In-game battery saves |
| `/storage/Retro/savestates` | Emulator state snapshots |
| `/storage/Retro/screenshots` | Captured game screenshots |
| `/storage/Retro/thumbnails` | Box art and thumbnail images |
| `/storage/.cache/{services,connman}` | Persistent service toggle markers and ConnMan network profiles |
| `/storage/.config` | Mutable application configuration state |
| `/storage/.update` | Downloaded `extra-life-<variant>-<version>.tar` OTA update bundles |

### Over-the-air updates

Extra Life sets `nix.enable = false` and runs zero Nix binaries, databases, or evaluators on the device. Ludo downloads verified bundles from Cloudflare R2 into `/storage/.update/`, and the initial RAM disk (`initrd`) applies them atomically on reboot.

1. **System identity**: `/etc/os-release` sets `ID=extra-life`, `VERSION_ID=<version>`, and `VARIANT_ID=<soc>` (for example `x86_64`, `rpi4`, `rpi5`, `rk3566`, or `h700`).
2. **Ludo updater patch**: `pkgs/ludo` patches `ludos/releases.go` and `menu/scene_updater.go` to read `VARIANT_ID` and `VERSION_ID` from `/etc/os-release`. Ludo queries the Cloudflare R2 manifest (`https://extralife-ota.wimpys.world/releases.json` or `EXTRA_LIFE_UPDATE_URL`) and matches `extra-life-<variant>-<version>.tar`. During the download to `/storage/.update/`, Ludo verifies the Secure Hash Algorithm 256 (SHA-256) digest with `grab.Request.SetChecksum`, then triggers a clean reboot (`/usr/sbin/shutdown -r now`).
3. **Update archive contents**: Each flat `.tar` archive contains `KERNEL`, `INITRD`, `SYSTEM`, and `SHA256SUMS`. `SYSTEM` is a read-only `zstd -19` SquashFS image of `/nix/store` that adds a `current-system -> <toplevel>` symlink through `pseudoFiles` so that `init=/nix/store/current-system/init` stays static.
4. **Early-boot application**: `boot.initrd.systemd.services.extra-life-apply-update` runs in `initrd` before the system mounts `/boot/SYSTEM`. The service checks `/storage/.update/extra-life-*.tar`, verifies `SHA256SUMS`, and renames existing `/boot/{KERNEL,INITRD,SYSTEM}` files to `.prev` for automatic rollback. It then moves the new `KERNEL`, `INITRD`, and `SYSTEM` files into `/boot`, deletes `/storage/.update/*.tar`, and boots into the new `SYSTEM` SquashFS.

## Roadmap

### Milestone 1: Core appliance and `x86_64-linux`

- Create the NixOS flake on `nixos-26.05` with `nixos-unstable` overrides (`pkgs.unstable`) and `teardown-order.patch` on Cage.
- Package `pkgs/ludo` (`v0.22.5`, Wayland build tags, bundled `ludo-assets` and `ludo-database`).
- Assemble the 33-core Libretro farm that matches `CoreForPlaylist`, and configure `/etc/ludo.toml` and `/storage/Retro`.
- Wire `-ludos` service toggles for ConnMan, BlueZ, Samba, OpenSSH, PipeWire, and Polkit.
- Ship the `x86_64-linux` disk image, installer ISO, `vm-retro` workflow, and Nix-free `/boot/SYSTEM` SquashFS OTA update pipeline.

### Milestone 2: Raspberry Pi family (`aarch64-linux`)

- Build ready-to-flash images for Secure Digital (SD) cards on Raspberry Pi 4, Raspberry Pi 400, Raspberry Pi 5, and Raspberry Pi Zero 2 W.
- Select `pcsx_rearmed_libretro` and ARM-appropriate cores, and tune VideoCore drivers for Kernel Mode Setting (KMS) and Mesa.
- Add hardware modules for RetroFlag cases (GPi Case, NESPi, SUPERPi, MegaPi, and PiStation), DeskPi cases, and Waveshare displays and cases.

### Milestone 3: ARM handhelds and portable integration

- Add board support packages on `aarch64-linux` for ARM handhelds, first on mainline-supported Rockchip devices.
- Map built-in General-Purpose Input/Output (GPIO) and Universal Serial Bus (USB) gamepads, sleep and wake states, and speaker and headphone outputs.
- Integrate battery indicators and backlight brightness controls into the heads-up display (HUD) and settings menu in Ludo.
