# Extra Life architecture

Extra Life (`extra-life`) is a NixOS retro game appliance built around Ludo and the Cage Wayland kiosk compositor. It gives extra life to classic games and hardware with a zero-jank, console-grade appliance experience across `x86_64` PCs, Raspberry Pi boards, and ARM handhelds.

## Product principles

Four product principles govern every architectural decision in Extra Life.

| Principle | Architectural rule | User impact |
| --- | --- | --- |
| Pure appliance | The system boots straight into `cage` and runs `ludo -ludos` on Wayland (`-tags wayland`). | The appliance exposes no desktop environment escape hatch, no text console prompts, and no RetroArch user interface. |
| Invisible Nix | Over-the-air (OTA) updates pull signed NixOS system closures from a binary cache with `nix-store --realise` and `switch-to-configuration`. | Users flash an image, copy read-only memory (ROM) files, and play with zero on-device Nix evaluation. |
| Opinionated emulation | The image ships a curated farm of Libretro cores that are symlinked into a single `cores_dir` directory. | Every supported playlist in Ludo (`CoreForPlaylist`) works out of the box without manual core downloads. |
| Universal hardware reach | A single flake builds `x86_64-linux` PC and virtual machine (VM) images alongside `aarch64-linux` board, handheld, and VM images, and runs `vm-retro` on `aarch64-darwin`. | The same appliance configuration runs on QEMU across Linux and Apple Silicon macOS, PC hardware, Raspberry Pi 4, 400, 5, and Zero 2 W, and ARM handhelds. |

## System overview

Extra Life replaces a general-purpose Linux distribution with a dedicated kiosk stack on NixOS.

```text
Hardware / KMS + DRM + Mesa + PipeWire
  └── systemd + Polkit + ConnMan + BlueZ + Samba + OpenSSH
        └── Cage Wayland compositor (with teardown-order.patch)
              └── ludo -ludos (Wayland native build, UID 1000)
                    └── Curated Libretro core farm (/run/current-system/sw/lib/retroarch/cores)
                          └── User data in /storage/Retro
```

At boot, systemd starts the audio, network, and storage services, then launches `cage` on the primary display. Cage starts `ludo -ludos` as user `ludo` (user identifier (UID) 1000). When `ludo` exits, Cage exits and systemd handles the power or restart state.

## Flake foundation

The repository flake tracks `nixos-26.05` (`github:NixOS/nixpkgs/nixos-26.05`) as the primary channel and exposes `nixos-unstable` at `pkgs.unstable` for package overrides. This layout keeps core system services on a stable NixOS release while emulator cores and Mesa drivers can use newer revisions. The flake structure is ready to switch the stable input to `nixos-26.11` when that release branches in November 2026.

The Wayland kiosk layer applies `teardown-order.patch` to the `cage` package. This patch fixes the shutdown order of the compositor so that Wayland clients and wlroots resources close cleanly on reboot or poweroff.

## Ludo package (`pkgs/ludo`)

Extra Life packages Ludo in `pkgs/ludo` with `pkgs.buildGoModule`.

| Attribute | Value | Purpose |
| --- | --- | --- |
| Upstream source | `libretro/ludo` | Official Libretro frontend written in Go |
| Revision | `7a2dc452c72e43dc06b5ecc711c3d03c8aeeb261` (`v0.22.5`) | Pinned release commit for reproducible builds |
| Submodules | `fetchSubmodules = true` | Pulls `ludo-assets` and `ludo-database` into the source tree |
| Build tags | `tags = [ "wayland" ]` | Compiles GLFW and OpenGL against native Wayland instead of X11 |

The build installs the compiled `ludo` binary with the bundled `ludo-assets` and `ludo-database` directories in the Nix store. The assets directory holds icons, fonts, and shaders, and the database directory holds No-Intro and Redump metadata.

## Ludo `-ludos` integration on NixOS

Ludo includes an appliance mode that the `-ludos` flag enables. Upstream Ludo assumes a LudOS filesystem layout with mutable configuration files and Filesystem Hierarchy Standard (FHS) binary paths. Extra Life maps every `-ludos` expectation onto declarative NixOS equivalents.

### Configuration and storage paths

Extra Life generates `/etc/ludo.toml` with appliance defaults and links it to the configuration path that Ludo reads at startup.

```toml
video_fullscreen = true
video_dark_mode = true
cores_dir = "/run/current-system/sw/lib/retroarch/cores"
assets_dir = "/run/current-system/sw/share/ludo/assets"
database_dir = "/run/current-system/sw/share/ludo/database"
playlists_dir = "/storage/Retro/playlists"
roms_dir = "/storage/Retro/roms"
savefiles_dir = "/storage/Retro/savefiles"
savestates_dir = "/storage/Retro/savestates"
screenshots_dir = "/storage/Retro/screenshots"
system_dir = "/storage/Retro/system"
thumbnails_dir = "/storage/Retro/thumbnails"
```

System assets and emulator cores live in the read-only Nix store. All mutable user data lives under `/storage/Retro`:

- `/storage/Retro/playlists` stores generated playlist files.
- `/storage/Retro/roms` holds user ROM sets that are organised by system name.
- `/storage/Retro/savefiles` and `/storage/Retro/savestates` store battery saves and state snapshots.
- `/storage/Retro/screenshots` and `/storage/Retro/thumbnails` hold captured images and box art.
- `/storage/Retro/system` stores BIOS files and firmware that specific Libretro cores require.

### Service toggles and binary paths

In `-ludos` mode, the Ludo settings menu toggles Secure Shell (SSH), Samba file shares, and Bluetooth. Ludo creates or deletes marker files in `/storage/.cache/services/{sshd,samba,bluez}.conf` to record these states. Ludo also invokes hardcoded FHS paths to manage services, Wi-Fi, and power state:

- `/usr/bin/systemctl` to start, stop, or restart `sshd`, `smbd`, and `bluetooth`
- `/usr/bin/connmanctl` to scan and connect to Wi-Fi networks, and `/storage/.cache/connman/<service>/settings` to write network credentials
- `/usr/bin/bash` to run helper commands
- `/usr/sbin/shutdown` to power off or reboot the appliance

Extra Life bridges these calls with three NixOS mechanisms:

1. **Path resolution**: `pkgs/ludo` patches `/usr/bin/*` and `/usr/sbin/*` to `/run/current-system/sw/bin/*`, or `systemd.tmpfiles.rules` links `/usr/bin/systemctl`, `/usr/bin/connmanctl`, `/usr/bin/bash`, and `/usr/sbin/shutdown`.
2. **Conditional service activation**: Systemd drop-in units on `sshd.service`, `samba-smbd.service`, and `bluetooth.service` set `ConditionPathExists=/storage/.cache/services/*.conf`. This configuration persists user service choices across reboots while `/etc` remains immutable.
3. **Polkit authorisation**: Polkit rules let user `ludo` (UID 1000) manage `sshd.service`, `samba-smbd.service`, `bluetooth.service`, `extra-life-update.service`, ConnMan, and systemd power actions without a password.

### Over-the-air updates (`extra-life-update`)

Extra Life adapts the Ludo updater in `ludos/releases.go` so that the appliance never evaluates Nix expressions locally.

1. Ludo queries the Extra Life release manifest endpoint for the target hardware architecture (`x86_64-linux` or `aarch64-linux`).
2. Each release entry publishes a semantic version tag and a signed Nix store path for the complete NixOS system closure.
3. When the user triggers an update in the Ludo interface, Ludo starts `extra-life-update.service` via `systemctl`.
4. The `extra-life-update` unit runs `nix-store --realise <store-path>` from the binary cache, updates `/nix/var/nix/profiles/system`, and runs `<store-path>/bin/switch-to-configuration switch`.

## Default Libretro core matrix

Extra Life constructs a unified core directory with `pkgs.symlinkJoin` (or `pkgs.runCommand`) so that every `.so` filename matches the `CoreForPlaylist` lookup table in Ludo (`core/core.go`).

|Core `.so` name (`CoreForPlaylist`)|Playlist / system names|Architecture notes|
|---|---|---|
|`stella2014_libretro`|`Atari - 2600`|All targets|
|`atari800_libretro`|`Atari - 5200`|All targets|
|`prosystem_libretro`|`Atari - 7800`|All targets|
|`virtualjaguar_libretro`|`Atari - Jaguar`|All targets|
|`handy_libretro`|`Atari - Lynx`|All targets|
|`hatari_libretro`|`Atari - ST`|All targets|
|`mednafen_wswan_libretro`|`Bandai - WonderSwan`, `Bandai - WonderSwan Color`|All targets|
|`nxengine_libretro`|`Cave Story`|All targets|
|`chailove_libretro`|`ChaiLove`|All targets|
|`bluemsx_libretro`|`Coleco - ColecoVision`, `Microsoft - MSX`, `Microsoft - MSX2`, `Spectravideo - SVI-318 - SVI-328`|All targets|
|`fbneo_libretro`|`FBNeo - Arcade Games`|All targets|
|`vecx_libretro`|`GCE - Vectrex`|All targets|
|`o2em_libretro`|`Magnavox - Odyssey2`, `Philips - Videopac+`|All targets|
|`mednafen_pce_libretro`|`NEC - PC Engine - TurboGrafx 16`, `NEC - PC Engine CD - TurboGrafx-CD`, `NEC - PC Engine SuperGrafx`|All targets|
|`mednafen_pcfx_libretro`|`NEC - PC-FX`|All targets|
|`fceumm_libretro`|`Nintendo - Family Computer Disk System`, `Nintendo - Nintendo Entertainment System`|All targets|
|`mgba_libretro`|`Nintendo - Game Boy Advance`|All targets|
|`gambatte_libretro`|`Nintendo - Game Boy`, `Nintendo - Game Boy Color`|All targets|
|`dolphin_libretro`|`Nintendo - GameCube`|`x86_64-linux` and capable `aarch64-linux` targets|
|`citra_libretro`|`Nintendo - Nintendo 3DS`|`x86_64-linux` and capable `aarch64-linux` targets|
|`mupen64plus_next_libretro`|`Nintendo - Nintendo 64`|All targets|
|`melonds_libretro`|`Nintendo - Nintendo DS`|All targets|
|`pokemini_libretro`|`Nintendo - Pokemon Mini`|All targets|
|`snes9x_libretro`|`Nintendo - Satellaview`, `Nintendo - Sufami Turbo`, `Nintendo - Super Nintendo Entertainment System`|All targets|
|`mednafen_vb_libretro`|`Nintendo - Virtual Boy`|All targets|
|`picodrive_libretro`|`Sega - 32X`, `Sega - PICO`|All targets|
|`flycast_libretro`|`Sega - Dreamcast`|All targets|
|`genesis_plus_gx_libretro`|`Sega - Game Gear`, `Sega - Master System - Mark III`, `Sega - Mega Drive - Genesis`, `Sega - Mega-CD - Sega CD`, `Sega - SG-1000`|All targets|
|`mednafen_saturn_libretro`|`Sega - Saturn`|All targets|
|`mednafen_ngp_libretro`|`SNK - Neo Geo Pocket`, `SNK - Neo Geo Pocket Color`|All targets|
|`swanstation_libretro` / `pcsx_rearmed_libretro`|`Sony - PlayStation`|`swanstation_libretro` on `x86_64-linux`, `pcsx_rearmed_libretro` on `aarch64-linux` (ARM)|
|`pcsx2_libretro`|`Sony - PlayStation 2`|`x86_64-linux` only|
|`ppsspp_libretro`|`Sony - PlayStation Portable`|All targets|

## Storage and partition layout

Extra Life images use a two-partition GUID Partition Table (GPT) layout that separates boot artefacts from the system store and user library.

| Partition | Filesystem | Mount point | Contents and behaviour |
| --- | --- | --- | --- |
| Partition 1 | `vfat` (EFI System Partition (ESP) / boot firmware) | `/boot` | Holds systemd-boot or U-Boot payloads, kernel images, initrd, and device-tree blobs on ARM targets. |
| Partition 2 | `ext4` (labelled `extralife-root`) | `/` | Expands automatically on first boot (`boot.growPartition = true`) and holds `/nix/store`, `/storage/.cache`, and `/storage/Retro`. |

Both `/nix/store` and `/storage/Retro` share the auto-expanding `ext4` root partition, so fixed partition boundaries never limit system updates or ROM collections. First-boot `systemd.tmpfiles.rules` create `/storage/Retro/{playlists,roms,savefiles,savestates,screenshots,system,thumbnails}` and `/storage/.cache/{services,connman}` with ownership set to `ludo:users`.

## Virtual machine development workflow (`vm-retro`)

Extra Life provides a fast local test loop through the `vm-retro` target (`just boot-disk`, `just boot-iso`, or `nix run .#vm-retro`) across `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin` (Apple Silicon macOS with a `linux-builder` such as Determinate Nix).

| Component | Configuration | Purpose |
| --- | --- | --- |
| Hypervisor | QEMU with Kernel-based Virtual Machine (KVM) on Linux or Hypervisor.framework (`hvf`) on macOS, plus Unified Extensible Firmware Interface (UEFI) (OVMF or EDK2 ARM) | Matches physical `x86_64` and `aarch64` UEFI boot behaviour at native CPU speed |
| Graphics | `virtio-vga-gl` (`x86_64-linux`), `ramfb` + `virtio-gpu-gl-pci` (`aarch64-linux`), or `ramfb` + `virtio-gpu-pci` (`aarch64-darwin`) | Runs Cage, Wayland, and Libretro cores across Linux OpenGL and macOS Cocoa |
| Display client | QEMU GTK display (`-display gtk,gl=on,zoom-to-fit=on`) on Linux or Cocoa display (`-display cocoa`) on macOS | Renders appliance frames and forwards keyboard, pointer, and controller input |
| Input passthrough | Automatic `virtio-input-host-pci` evdev passthrough on Linux, and `--usb-device VID:PID` (`usb-host`) on macOS and Linux | Connects host gamepads directly to the appliance |
| Audio | PipeWire backend on Linux or CoreAudio backend on macOS | Routes appliance game audio to the host audio session |
| Network and SSH | User-mode network with host port `2222` forwarded to guest port `22` | Allows SSH access and `rsync` or `scp` ROM transfers during local tests |
| Persistent state | `.vm/` (git-ignored inside the repository) | Preserves the writable disk image, `/storage/Retro` library, and UEFI NVRAM across runs |

## Milestones

Delivery proceeds in three milestones that expand hardware coverage on top of the shared appliance core.

### Milestone 1: Core appliance and `x86_64-linux`

- Create the NixOS flake that tracks `nixos-26.05` and `nixos-unstable` (`pkgs.unstable`), and patch `cage` with `teardown-order.patch`.
- Package `pkgs/ludo` (`v0.22.5`, commit `7a2dc452c72e43dc06b5ecc711c3d03c8aeeb261`, `fetchSubmodules = true`, `tags = [ "wayland" ]`).
- Assemble the default Libretro core farm so that every core matches the `CoreForPlaylist` map in Ludo.
- Configure the Cage kiosk session, `/etc/ludo.toml`, `/storage/Retro` directories, and `-ludos` integration for ConnMan, BlueZ, Samba, OpenSSH, PipeWire, and Polkit.
- Deliver the `x86_64-linux` installer ISO, disk image, `vm-retro` workflow, and `extra-life-update` binary cache OTA service.

### Milestone 2: Raspberry Pi family (`aarch64-linux`)

- Build ready-to-flash Secure Digital (SD) card images for Raspberry Pi 4, Raspberry Pi 400, Raspberry Pi 5, and Raspberry Pi Zero 2 W.
- Select `pcsx_rearmed_libretro` and platform-appropriate cores for ARM targets, and tune VideoCore KMS and Mesa drivers.
- Add declarative hardware modules for RetroFlag cases (GPi Case, NESPi, SUPERPi, MegaPi, and PiStation), DeskPi cases, and Waveshare displays and cases.

### Milestone 3: ARM handhelds and portable integration

- Add `aarch64-linux` board support packages for ARM handhelds, first on mainline-supported Rockchip devices.
- Map built-in GPIO and USB gamepads, sleep and wake power states, and stereo speaker and headphone outputs.
- Integrate battery level indicators and backlight brightness controls directly into the Ludo heads-up display (HUD) and settings menu.
