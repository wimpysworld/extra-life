# Architecture

Extra Life (`extra-life`, <https://extralife.wimpys.world>) is a NixOS retro game appliance built around [Ludo](https://ludo.libretro.com/) and the [Cage](https://www.hjdskes.nl/projects/cage/) Wayland kiosk compositor. It delivers a console experience across `x86_64-linux` personal computers (PCs), Raspberry Pi boards, and ARM handhelds.

## Product principles

Four product principles govern every architectural decision in Extra Life.

| Principle | Architectural rule | User impact |
| --- | --- | --- |
| Pure appliance | The system boots straight into `cage` and runs `ludo -ludos` on Wayland (`-tags wayland`). | The appliance exposes no desktop environment escape hatch, no text console prompts, and no RetroArch user interface (UI). |
| Invisible Nix | Continuous Integration (CI) runs Nix at build time only. The appliance sets `nix.enable = false` and applies updates from Cloudflare R2 in the initial RAM disk (`initrd`). | Users flash an image, copy read-only memory (ROM) files, and apply updates with zero runtime Nix binaries, databases, or evaluators. |
| Opinionated emulation | The image ships 33 curated Libretro cores that are symlinked into a single `cores_dir` directory. | Every supported playlist in Ludo (`CoreForPlaylist`) works out of the box without manual core downloads. |
| Universal hardware reach | One flake builds `x86_64-linux` PC and virtual machine (VM) images alongside `aarch64-linux` board, handheld, and VM images, and runs `vm-retro` on `aarch64-darwin`. | The same configuration runs on QEMU across Linux and Apple Silicon macOS, PC hardware, Raspberry Pi boards, and ARM handhelds. |

## System stack

Extra Life replaces a general-purpose Linux distribution with a dedicated kiosk stack on NixOS.

```text
Hardware / KMS + DRM + Mesa + PipeWire
  └── systemd + Polkit + ConnMan + BlueZ + Samba + OpenSSH
        └── Cage Wayland compositor (with teardown-order.patch)
              └── ludo -ludos (Wayland native build, UID 1000)
                    └── Curated Libretro core farm (/run/current-system/sw/lib/retroarch/cores)
                          └── User data in /storage/Retro
```

At boot, systemd starts the audio, network, and storage services, then launches `cage` on the primary display. Cage starts `ludo -ludos` as user `ludo` with user identifier (UID) 1000. When `ludo` exits, Cage exits and systemd handles the power or restart state.

## Flake foundation

The repository flake tracks `nixos-26.05` (`github:NixOS/nixpkgs/nixos-26.05`) as the primary channel and exposes `nixos-unstable` at `pkgs.unstable` for package overrides. This structure keeps core system services on a stable NixOS release while emulator cores and Mesa drivers can use newer revisions. The flake layout is ready to switch the stable input to `nixos-26.11` when that release branches in November 2026.

The Wayland kiosk layer applies `teardown-order.patch` to the `cage` package. This patch fixes the shutdown order of the compositor so that Wayland clients and wlroots resources close cleanly on reboot or poweroff.

## Ludo package and `-ludos` integration

Extra Life packages Ludo in `pkgs/ludo` with `pkgs.buildGoModule`.

| Attribute | Value | Purpose |
| --- | --- | --- |
| Upstream source | `libretro/ludo` | Official Libretro frontend written in Go |
| Revision | `7a2dc452c72e43dc06b5ecc711c3d03c8aeeb261` (`v0.22.5`) | Pinned release commit for reproducible builds |
| Submodules | `fetchSubmodules = true` | Pulls `ludo-assets` and `ludo-database` into the source tree |
| Build tags | `tags = [ "wayland" ]` | Compiles GLFW and OpenGL against native Wayland instead of X11 |

The build installs the compiled `ludo` binary with `ludo-assets` and `ludo-database` in the Nix store. The `ludo-assets` directory holds icons, fonts, and shaders, and `ludo-database` holds No-Intro and Redump metadata.

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

Read [Supported Systems](Supported-Systems) for the full 33-core `CoreForPlaylist` matrix and `/storage/Retro` directory details.

### Declarative service toggles and binary paths

In `-ludos` mode, the Ludo settings menu toggles Secure Shell (SSH), Samba file shares, and Bluetooth. Ludo creates or deletes marker files in `/storage/.cache/services/{sshd,samba,bluez}.conf` to record these states. Upstream Ludo invokes hardcoded Filesystem Hierarchy Standard (FHS) paths to manage services, Wi-Fi, and power state:

- `/usr/bin/systemctl` to start, stop, or restart `sshd`, `smbd`, and `bluetooth`
- `/usr/bin/connmanctl` to scan and connect to Wi-Fi networks, and `/storage/.cache/connman/<service>/settings` to store network credentials
- `/usr/bin/bash` to run helper commands
- `/usr/sbin/shutdown` to power off or reboot the appliance

Extra Life bridges these calls with three NixOS mechanisms:

1. **Path resolution**: `pkgs/ludo` patches `/usr/bin/*` and `/usr/sbin/*` to `/run/current-system/sw/bin/*`, or `systemd.tmpfiles.rules` links `/usr/bin/systemctl`, `/usr/bin/connmanctl`, `/usr/bin/bash`, and `/usr/sbin/shutdown`.
2. **Conditional service activation**: Systemd drop-in units on `sshd.service`, `samba-smbd.service`, and `bluetooth.service` set `ConditionPathExists=/storage/.cache/services/*.conf`. This configuration persists user service choices across reboots while `/etc` stays immutable.
3. **Polkit authorisation**: Polkit rules let user `ludo` (UID 1000) manage `sshd.service`, `samba-smbd.service`, `bluetooth.service`, ConnMan, and systemd power actions without a password.

## Two-partition storage layout

Extra Life images use a two-partition GUID Partition Table (GPT) layout that separates immutable boot and system artefacts from mutable user data.

| Partition | Filesystem and label | Mount point | Contents and behaviour |
| --- | --- | --- | --- |
| Partition 1 | `vfat` (labelled `EXTRALIFE`) | `/boot` | Holds the bootloader (Unified Extensible Firmware Interface (UEFI) `BOOTX64.EFI` or `BOOTAA64.EFI`, U-Boot, or Raspberry Pi firmware) and `.dtb` files. Also stores `KERNEL`, `INITRD`, `SYSTEM` (read-only `zstd` SquashFS mounted at `/nix/store`), and `.prev` rollback files. |
| Partition 2 | `ext4` (labelled `STORAGE`) | `/storage` | Expands automatically on first boot and holds `/storage/Retro/{playlists,roms,savefiles,savestates,screenshots,system,thumbnails}`, `/storage/.cache/{services,connman}`, `/storage/.config`, and `/storage/.update`. |

At boot, `initrd` mounts `/boot/SYSTEM` read-only at `/nix/store` so that sudden power loss cannot corrupt the operating system store. First-boot `systemd.tmpfiles.rules` create `/storage/Retro/*`, `/storage/.cache/{services,connman}`, `/storage/.config`, and `/storage/.update` with ownership set to `ludo:users`.

## Over-the-air update pipeline

Extra Life runs with `nix.enable = false` and ships zero Nix binaries, databases, or evaluators at runtime. Over-the-air (OTA) updates use the built-in `Updater` menu in Ludo, Cloudflare R2 storage at `extralife-ota.wimpys.world`, and an atomic swap in `initrd`.

1. **System identity**: `/etc/os-release` defines `ID=extra-life`, `VERSION_ID=<version>`, and `VARIANT_ID=<soc>` (for example `x86_64`, `rpi4`, `rpi5`, `rk3566`, or `h700`).
2. **Ludo updater patch**: `pkgs/ludo` patches `ludos/releases.go` and `menu/scene_updater.go` to read `VARIANT_ID` and `VERSION_ID` from `/etc/os-release`. Ludo queries the Cloudflare R2 manifest (`https://extralife-ota.wimpys.world/releases.json` or `EXTRA_LIFE_UPDATE_URL`) and matches `extra-life-<variant>-<version>.tar`. During the download to `/storage/.update/`, Ludo verifies the Secure Hash Algorithm 256 (SHA-256) digest with `grab.Request.SetChecksum`, then runs `/usr/sbin/shutdown -r now`.
3. **Update archive contents**: Each `extra-life-<variant>-<version>.tar` bundle is a flat archive that contains `KERNEL`, `INITRD`, `SYSTEM`, and `SHA256SUMS`. `SYSTEM` is a read-only `zstd -19` SquashFS image of `/nix/store` that adds a `current-system -> <toplevel>` symlink through `pseudoFiles`. That symlink keeps the kernel command-line parameter `init=/nix/store/current-system/init` static across updates.
4. **Early-boot application**: `boot.initrd.systemd.services.extra-life-apply-update` runs in `initrd` before the system mounts `/boot/SYSTEM`. The service checks `/storage/.update/extra-life-*.tar`, verifies `SHA256SUMS`, and renames existing `/boot/{KERNEL,INITRD,SYSTEM}` files to `.prev` for automatic rollback. It then moves the new `KERNEL`, `INITRD`, and `SYSTEM` files into `/boot`, deletes `/storage/.update/*.tar`, and boots into the new `SYSTEM` SquashFS.

## Hardware enablement and SoC-family catalogue

All hardware modules, kernels, U-Boot bootloaders, and device or case definitions live in this single monorepo. The repository places System on a Chip (SoC), board, and case modules in `nixos/modules/hardware/{soc,boards,cases}/` and image builders in `nixos/modules/images/`. Custom kernel and bootloader packages live in `pkgs/kernels/` and `pkgs/uboot/`, while `nixos/devices/devices.toml` defines the declarative device catalogue.

The flake evaluates `lib.nixosSystem` once per SoC family rather than once per retail board. Nix parses `nixos/devices/devices.toml` with `builtins.fromTOML` so that `just check` stays fast as the catalogue grows. Each board image derivation pairs the shared SoC closure with the U-Boot and Device Tree Blob (DTB) files for that board. Read [Supported Hardware](Supported-Hardware) for the active SoC targets, supported devices, the hardware roadmap, and excluded hardware.

### Shared SoC and per-board layers

Extra Life models its hardware architecture on ROCKNIX so that every board in an SoC family shares one root filesystem closure. U-Boot selects the board DTB with Successive Approximation Register Analogue-to-Digital Converter (SARADC) probing or explicit `FDT` entries. `OpenABL` targets use UEFI and Boot Loader Specification (BLS) entries. At boot, the system identifies the board from the device tree on ARM or Desktop Management Interface (DMI) attributes on `x86_64`. The runtime layer applies Advanced Linux Sound Architecture (ALSA) Use Case Manager (UCM2) (`alsa-ucm-conf`) audio profiles and Direct Rendering Manager (DRM) panel orientation. Display drivers load panel timing firmware for Mobile Industry Processor Interface Display Serial Interface (MIPI-DSI) screens from `/lib/firmware/panels/*.panel`.

| Layer | Scope | Artefacts and runtime mechanics |
| --- | --- | --- |
| Kernel and firmware | Shared per SoC | Linux kernel (`Image` or `bzImage`), built-in early firmware (`CONFIG_EXTRA_FIRMWARE`), and kernel modules build once per SoC family. |
| Graphics and root filesystem | Shared per SoC | Every board in the SoC family shares the Mesa Graphics Processing Unit (GPU) stack (`radeonsi`, `iris`, `vc4`, `v3d`, `panfrost`, `freedreno`) and root filesystem closure. |
| Bootloader and DTB selection | Per board | Boot partitions select the DTB through `FDTDIR /device_trees` with U-Boot SARADC or board auto-detection, explicit `FDT` entries, or `OpenABL` UEFI and BLS entries. |
| Runtime board detection | Per board | Early boot detection reads `/sys/firmware/devicetree/base/model` and `/proc/device-tree/compatible` on ARM, or `/sys/class/dmi/id/{sys_vendor,product_name}` on `x86_64`. |
| Controller abstraction | Per board | `InputPlumber` loads composite YAML profiles from `/usr/share/inputplumber/devices/*.yaml`, and `rocknix-joypad` with `SDL_GameControllerDB` maps legacy handheld controls. |
| Audio and display quirks | Per board | ALSA UCM2 profiles (`alsa-ucm-conf`), MIPI-DSI timing firmware (`/lib/firmware/panels/*.panel`), and DRM panel orientation configure audio and display quirks. |
