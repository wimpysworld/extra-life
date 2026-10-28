<h1 align="center">
  <img src="assets/logo.svg" alt="Extra Life Logo" width="256" />
  <br />
  Extra Life
</h1>

<p align="center"><b>Give Extra Life to Classic Games and Hardware 🕹</b></p>

Extra Life (`extra-life`, <https://extralife.wimpys.world>) is a retro game appliance built with [NixOS](https://nixos.org/). It boots directly into [Ludo](https://ludo.libretro.com/) inside the [Cage](https://www.hjdskes.nl/projects/cage/) Wayland kiosk compositor. The appliance runs classic games across `x86_64-linux` personal computers (PCs), Raspberry Pi boards, and ARM handhelds. It has no desktop environment, no text consoles, no RetroArch menus, and no runtime Nix binaries, databases, or evaluators.

```bash
# Run the appliance in a local QEMU virtual machine
nix run .#vm-retro
```

## Product principles

Four product principles govern every decision in Extra Life.

| Principle | Rule | Impact |
| --- | --- | --- |
| Pure appliance | The system boots straight into `cage` and runs `ludo -ludos` on native Wayland. | You get a console experience with no desktop escape hatch, no text console prompts, and no RetroArch user interface (UI). |
| Invisible Nix | Continuous Integration (CI) runs Nix at build time only. The appliance sets `nix.enable = false` and applies updates from Cloudflare R2 in the initial RAM disk (`initrd`). | You flash an image, copy read-only memory (ROM) files, and apply over-the-air (OTA) updates with zero runtime Nix tools. |
| Opinionated emulation | The image ships 33 curated Libretro cores in a single `cores_dir` directory. | Every supported playlist in Ludo (`CoreForPlaylist`) works out of the box without manual core downloads. |
| Universal hardware reach | One flake builds `x86_64-linux` PC and virtual machine (VM) images alongside `aarch64-linux` board and handheld images, and supports `aarch64-darwin` hosts. | The same configuration runs on QEMU across Linux and Apple Silicon macOS, PC hardware, Raspberry Pi boards, and ARM handhelds. |

## Quick start

### Boot the appliance in a virtual machine

Build and boot either the writable Unified Extensible Firmware Interface (UEFI) disk image or the live ISO in `vm-retro`. The disk image uses a GUID Partition Table (GPT) layout. The VM runs on `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin` (Apple Silicon macOS with a `linux-builder`).

```bash
# Build the UEFI GPT disk image, seed .vm/disk.qcow2 (64 GB), and boot it
just boot-disk

# Or build the live ISO and boot it
just boot-iso
```

### Copy ROMs and BIOS files

The `STORAGE` partition mounts at `/storage` and holds all user files under `/storage/Retro`. In `vm-retro`, host port `2222` forwards to Secure Shell (SSH) port `22` on the guest. On hardware, enable SSH or Samba from the Ludo settings menu.

```bash
# Copy ROM sets and BIOS files into the running virtual machine over SSH
rsync -avP -e "ssh -p 2222" ./roms/ ludo@localhost:/storage/Retro/roms/
rsync -avP -e "ssh -p 2222" ./system/ ludo@localhost:/storage/Retro/system/
```

## Documentation

Detailed reference tables, system layouts, and developer workflows live in the [Extra Life Wiki](https://github.com/wimpysworld/extra-life/wiki) and the architecture specification:

- [Extra Life Wiki: Home](https://github.com/wimpysworld/extra-life/wiki): Overview of the appliance, product principles, and ROM and Basic Input/Output System (BIOS) transfers.
- [Supported Systems](https://github.com/wimpysworld/extra-life/wiki/Supported-Systems): The grouped system summary, the full 33-core `CoreForPlaylist` matrix, and the `/storage/Retro` directory structure.
- [Architecture](https://github.com/wimpysworld/extra-life/wiki/Architecture): The kiosk stack, Ludo `-ludos` integration, two-partition `EXTRALIFE` + `STORAGE` layout, Cloudflare R2 OTA pipeline, and SoC hardware catalogue.
- [Development](https://github.com/wimpysworld/extra-life/wiki/Development): The `nix develop` shell, `justfile` commands, `vm-retro` on Linux and Apple Silicon macOS, and USB and `evdev` controller passthrough.
- [Local architecture reference (`docs/architecture.md`)](docs/architecture.md): Complete repository architecture reference.

## Roadmap

- **Milestone 1 (`x86_64-linux` appliance)**: Ship the `nixos-26.05` flake, Wayland `ludo` (`v0.22.5`), 33-core farm, `-ludos` services, `vm-retro`, and SquashFS OTA updates.
- **Milestone 2 (Raspberry Pi)**: Ship Secure Digital (SD) images for Raspberry Pi 4, 400, 5, and Zero 2 W, plus RetroFlag, DeskPi, and Waveshare cases.
- **Milestone 3 (ARM handhelds)**: Ship Wave 1 mainline handheld closures (`rk3566`, `h700`, `sm8250`, `sm8550`, `rk3326`), `InputPlumber` profiles, and Ludo battery and backlight controls.
