# Extra Life

Extra Life (`extra-life`) is a NixOS retro game appliance flake that runs `ludo -ludos` in the `cage` Wayland kiosk compositor on `x86_64-linux` and `aarch64-linux`. The flake supports local virtual machine (VM) runs on `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`.

## Build and test

- Evaluate the flake outputs: `just check`
- Format Nix files: `just fmt`
- Build the default package (`ludo` on Linux, `vm-retro` on macOS): `nix build`
- Build the `ludo` package on Linux: `nix build .#ludo`
- Build the installer ISO or disk image for the host architecture (`x86_64` or `aarch64`): `just build-iso` or `just build-disk`
- Boot the local development VM from the built disk image or ISO: `just boot-disk`, `just boot-iso`, or `nix run .#vm-retro`. Local VMs use `kvm` on Linux, `hvf` with Cocoa on Apple Silicon macOS, and `linux-builder` on macOS for image builds.

## Architecture notes

- Track `nixos-26.05` as the primary `nixpkgs` input. Expose `nixos-unstable` at `pkgs.unstable` for package overrides. Keep the flake structure ready to switch to `nixos-26.11` when that release branches.
- Keep the system a pure appliance. Boot straight into `cage`. Run `ludo -ludos` as user `ludo` (user identifier (UID) 1000).
- Do not add a desktop environment, display manager, X11 server, Xwayland layer, or RetroArch user interface (UI).
- Package `ludo` in `pkgs/ludo` with `buildGoModule`, `fetchSubmodules = true`, and `tags = [ "wayland" ]`. Install `ludo-assets` and `ludo-database` into the Nix store.
- Set `meta.maintainers = with lib.maintainers; [ flexiondotorg ];` in all local packages under `pkgs/`.
- Apply `teardown-order.patch` to `cage` so that Wayland clients and wlroots resources close cleanly on shutdown.
- Assemble Libretro cores into `/run/current-system/sw/lib/retroarch/cores` with `pkgs.symlinkJoin` or `pkgs.runCommand`. Every `.so` filename must match the `CoreForPlaylist` lookup table in Ludo (`core/core.go`).
- Select PlayStation cores by architecture: use `swanstation_libretro` on `x86_64-linux` and `pcsx_rearmed_libretro` on `aarch64-linux`. Restrict `pcsx2_libretro` to `x86_64-linux`.
- Use Nix only at build time (`nix.enable = false` on the appliance). Deliver over-the-air (OTA) updates as `extra-life-<variant>-<version>.tar` bundles (`KERNEL`, `INITRD`, `SYSTEM` SquashFS, and `SHA256SUMS`) from Cloudflare R2 (`releases.json`). Patch `pkgs/ludo` (`ludos/releases.go` and `menu/scene_updater.go`) to read `VARIANT_ID` and `VERSION_ID` from `/etc/os-release`. Verify SHA-256 digests in Ludo, download updates into `/storage/.update/`, and reboot. Apply updates in `initrd` (`extra-life-apply-update.service`) with `.prev` rollback before `initrd` mounts `/boot/SYSTEM`.
- Use a two-partition appliance layout. Partition 1 (`/boot`, `vfat`, label `EXTRALIFE`) holds the bootloader, `.dtb` files, `KERNEL`, `INITRD`, and the read-only `zstd` `SYSTEM` SquashFS. The `SYSTEM` SquashFS holds `/nix/store` with a `current-system` symlink. Partition 2 (`/storage`, `ext4`, label `STORAGE`) expands on first boot and holds `/storage/Retro`, `/storage/.cache/{services,connman}`, and `/storage/.update`.
- Keep hardware modules (`nixos/modules/hardware/{soc,boards,cases}/`), image builders (`nixos/modules/images/`), kernels (`pkgs/kernels/`), bootloaders (`pkgs/uboot/`), and the device catalogue (`nixos/devices/devices.toml`) in this monorepo. Do not split hardware enablement into separate repositories.
- Scope `nixosConfigurations` (`lib.nixosSystem`) by System on a Chip (SoC) family, not per retail board. Use the SoC families `x86_64`, `rpi4`, `rpi5`, `rpi02w`, `rk3566`, `h700`, `sm6115`, `sm8250`, `sm8550`, and `rk3326`. This scope keeps `just check` fast and ensures that all boards in an SoC family share one system closure.
- Isolate board-specific differences to `nixos/devices/devices.toml`, Device Tree Blobs (`.dtb`), U-Boot payloads, and `InputPlumber` YAML profiles. Isolate board audio to Advanced Linux Sound Architecture (ALSA) Use Case Manager (UCM) profiles. Match boot-time quirks with `/sys/firmware/devicetree/base/model` or Desktop Management Interface (DMI) strings.
- Prefer the current NixOS Long Term Support (LTS) kernel (`pkgs.linuxPackages`) and open-source Mesa drivers (`radeonsi`, `iris`, `vc4`, `v3d`, `panfrost`, `freedreno`). When drivers, Device Tree Blobs (`.dtb`), a Board Support Package (BSP), or binary blobs require another kernel series, package that kernel in `pkgs/kernels/`. Source that kernel from `nixpkgs`, `pkgs.unstable`, a pinned historical `nixpkgs` revision, or a vendor BSP tree.

## Gotchas

- Upstream `ludo -ludos` calls hardcoded Filesystem Hierarchy Standard (FHS) paths (`/usr/bin/systemctl`, `/usr/bin/connmanctl`, `/usr/bin/bash`, `/usr/sbin/shutdown`). Patch those paths in `pkgs/ludo` or link them with `systemd.tmpfiles.rules`.
- Service toggles in Ludo create or delete `/storage/.cache/services/{sshd,samba,bluez}.conf`. Gate `sshd.service`, `samba-smbd.service`, and `bluetooth.service` with `ConditionPathExists`. Grant Polkit rules to user `ludo` (UID 1000).
- Read `docs/architecture.md` for the system architecture and partition layout, `wiki/Supported-Systems.md` for the core matrix, and `wiki/Supported-Hardware.md` for supported devices and the hardware roadmap.
