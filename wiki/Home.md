# Extra Life Wiki

Extra Life (`extra-life`, <https://extralife.wimpys.world>) is a retro game appliance built with [NixOS](https://nixos.org/). It boots directly into [Ludo](https://ludo.libretro.com/) inside the [Cage](https://www.hjdskes.nl/projects/cage/) Wayland kiosk compositor. The appliance runs classic games on `x86_64-linux` personal computers (PCs), Raspberry Pi boards, and ARM handhelds. It has no desktop environment, no text consoles, no RetroArch menus, and no runtime Nix binaries, databases, or evaluators.

## Wiki guides

- [Supported Systems](Supported-Systems): Read the grouped system summary, the 33-core `CoreForPlaylist` matrix, and the `/storage/Retro` directory layout.
- [Supported Hardware](Supported-Hardware): Read the active System on a Chip (SoC) targets, supported boards and handhelds, the hardware roadmap, and excluded hardware.
- [Architecture](Architecture): Read the system stack, flake design, `-ludos` integration, two-partition storage layout, over-the-air (OTA) update pipeline, and SoC hardware layers.
- [Development](Development): Set up `nix develop`, run `just` recipes, boot `vm-retro` on Linux or macOS, and pass controllers through.

## Product principles

Four product principles govern every decision in Extra Life.

| Principle | Rule | Impact |
| --- | --- | --- |
| Pure appliance | The system boots straight into `cage` and runs `ludo -ludos` on native Wayland. | You get a console experience with no desktop escape hatch, no text console prompts, and no RetroArch user interface (UI). |
| Invisible Nix | Continuous Integration (CI) runs Nix at build time only. The appliance sets `nix.enable = false` and applies updates from Cloudflare R2 in the initial RAM disk (`initrd`). | You flash an image, copy read-only memory (ROM) files, and apply OTA updates with zero runtime Nix tools. |
| Opinionated emulation | The image ships 33 curated Libretro cores in a single `cores_dir` directory. | Every supported playlist in Ludo (`CoreForPlaylist`) works out of the box without manual core downloads. |
| Universal hardware reach | One flake builds `x86_64-linux` PC and virtual machine (VM) images alongside `aarch64-linux` board and handheld images, and supports `aarch64-darwin` hosts. | The same configuration runs on QEMU across Linux and Apple Silicon macOS, PC hardware, Raspberry Pi boards, and ARM handhelds. |

## Copy ROMs and BIOS files into `/storage/Retro`

Extra Life stores all user data on the second partition (`STORAGE`), which mounts at `/storage`. Place your game ROM sets in `/storage/Retro/roms/<System Name>/` and place Basic Input/Output System (BIOS) firmware files in `/storage/Retro/system/`.

Enable Secure Shell (SSH) or Samba in the Ludo settings menu to copy files over the network. You can also mount the `STORAGE` partition directly on another computer.

```bash
# Copy ROM sets to a local VM on port 2222
rsync -avP -e "ssh -p 2222" ./roms/ ludo@localhost:/storage/Retro/roms/

# Copy BIOS files to a local VM on port 2222
rsync -avP -e "ssh -p 2222" ./system/ ludo@localhost:/storage/Retro/system/

# Copy ROM sets to a physical appliance on the local network
rsync -avP ./roms/ ludo@extra-life.local:/storage/Retro/roms/
```

After you transfer your files, select **Scan directory** in Ludo to generate playlists under `/storage/Retro/playlists/`. Read [Supported Systems](Supported-Systems) for exact system directory names and core details.
