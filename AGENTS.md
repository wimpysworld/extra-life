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
- Never evaluate Nix expressions on the appliance. Over-the-air (OTA) updates in `extra-life-update` must fetch pre-built closures with `nix-store --realise` and run `switch-to-configuration`.
- Keep `/etc` immutable on the `ext4` root partition (`extralife-root`), which expands automatically on first boot. Store mutable user data under `/storage/Retro` and persistent service and network state under `/storage/.cache/{services,connman}`.
- Keep hardware modules (`nixos/modules/hardware/{soc,boards,cases}/`), image builders (`nixos/modules/images/`), kernels (`pkgs/kernels/`), bootloaders (`pkgs/uboot/`), and the device catalogue (`nixos/devices/devices.toml`) in this monorepo. Do not split hardware enablement into separate repositories.
- Scope `nixosConfigurations` (`lib.nixosSystem`) by System on a Chip (SoC) family, not per retail board. Use the SoC families `x86_64`, `rpi4`, `rpi5`, `rpi02w`, `rk3566`, `h700`, `sm8250`, `sm8550`, and `rk3326`. This scope keeps `just check` fast and ensures that all boards in an SoC family share one system closure.
- Isolate board-specific differences to `nixos/devices/devices.toml`, Device Tree Blobs (`.dtb`), U-Boot payloads, and `InputPlumber` YAML profiles. Isolate board audio to Advanced Linux Sound Architecture (ALSA) Use Case Manager (UCM) profiles. Match boot-time quirks with `/sys/firmware/devicetree/base/model` or Desktop Management Interface (DMI) strings.
- Target mainline Linux and open-source Mesa (`radeonsi`, `iris`, `vc4`, `v3d`, `panfrost`, `freedreno`) in Wave 1. Defer legacy vendor Board Support Package (BSP) kernels until after Wave 1.

## Gotchas

- Upstream `ludo -ludos` calls hardcoded Filesystem Hierarchy Standard (FHS) paths (`/usr/bin/systemctl`, `/usr/bin/connmanctl`, `/usr/bin/bash`, `/usr/sbin/shutdown`). Patch those paths in `pkgs/ludo` or link them with `systemd.tmpfiles.rules`.
- Service toggles in Ludo create or delete `/storage/.cache/services/{sshd,samba,bluez}.conf`. Gate `sshd.service`, `samba-smbd.service`, and `bluetooth.service` with `ConditionPathExists`. Grant Polkit rules to user `ludo` (UID 1000).
- Read `docs/architecture.md` for the full core matrix, partition layout, and milestone plan.
