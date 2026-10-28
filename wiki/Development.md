# Development

Extra Life provides a reproducible development environment for `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin` (Apple Silicon macOS). Use it to evaluate flake outputs, format Nix code, build images and over-the-air (OTA) bundles, and run `vm-retro`.

## Development shell (`nix develop` and `direnv`)

The repository includes a flake development shell (`devShells.default`) and an `.envrc` file for `direnv`. The shell installs `just`, `nixfmt`, `nixfmt-tree`, `deadnix`, `statix`, `actionlint`, `nix-output-monitor` (`nom`), `jq`, `rclone`, `sops`, `wrangler`, and `vm-retro`.

```bash
# Enter the development shell directly
nix develop

# Or allow direnv to load the flake environment automatically
direnv allow
```

## `justfile` commands

Run `just` with no arguments to list all recipes in the repository `justfile`.

| Command | Action |
| --- | --- |
| `just check` | Evaluates every `nixosConfigurations.<name>.config.system.build.toplevel.drvPath` and every per-system package and formatter derivation for the host system. |
| `just fmt` | Runs `deadnix`, `statix fix`, and `nix fmt` (`nixfmt-tree`) across the repository or on specific paths. |
| `just build-pkg [pkg]` | Builds a single package from the flake (defaults to `ludo`) and writes the symlink to `result-<pkg>`. |
| `just build-disk` | Builds the Unified Extensible Firmware Interface (UEFI) GUID Partition Table (GPT) disk image (`.#disk-image`) into `result-disk`. |
| `just build-iso` | Builds the live bootable ISO image (`.#iso`) into `result-iso` and copies it to `.vm/extra-life.iso`. |
| `just boot-disk` | Builds `.#disk-image`, seeds a writable 64 GB `.vm/disk.qcow2` image if needed, and boots `vm-retro`. |
| `just boot-iso` | Builds `.#iso` and boots `.vm/extra-life.iso` in `vm-retro`. |
| `just vm *args` | Passes arguments (`--shutdown`, `--kill`, `--usb-device VID:PID`) directly to `nix run .#vm-retro`. |
| `just build-ota` | Builds the OTA update bundle (`.#ota-bundle`) into `result-ota`. |
| `just publish-ota` | Builds `.#ota-bundle`, decrypts Cloudflare R2 credentials from `secrets/secrets.yaml` with `sops`, and uploads `result-ota/` to `r2:extralife-ota/` (`extralife-ota.wimpys.world`) with `rclone`. |
| `just cf-setup` | Decrypts Cloudflare credentials from `secrets/secrets.yaml` with `sops` and provisions the `extralife-ota` R2 bucket and `extralife-ota.wimpys.world` custom domain with `wrangler`. |
| `just update` | Updates `flake.lock` inputs (`just update [input] [lock_only] [override_url]`). |
| `just clean` | Stops `vm-retro` if it runs, deletes `.vm/`, and removes `result` and `result-*` symlinks. |

```bash
# Validate all NixOS configurations and package derivations
just check

# Lint and format all Nix files
just fmt

# Build the UEFI GPT disk image and boot it in QEMU
just boot-disk

# Build the OTA update bundle locally
just build-ota
```

## Virtual machine workflow (`vm-retro`)

The `vm-retro` package (`pkgs/vm-retro`) launches and controls a local QEMU appliance VM. It stores runtime state, UEFI Non-Volatile Random-Access Memory (NVRAM) (`OVMF_VARS.fd`), and the writable 64 GB `disk.qcow2` drive inside `.vm/` (or `EXTRA_LIFE_VM_DIR`).

| Host platform | QEMU binary and accelerator | Display and GPU device | Audio backend |
| --- | --- | --- | --- |
| `x86_64-linux` | `qemu-system-x86_64` with Kernel-based Virtual Machine (`accel=kvm`), `q35`, 16 GB RAM | GTK (`-display gtk,gl=on,zoom-to-fit=on`) with `virtio-vga-gl,hostmem=4G,blob=true` | PipeWire (`-audiodev pipewire`) |
| `aarch64-linux` | `qemu-system-aarch64` with `accel=kvm`, `virt`, 8 GB RAM | GTK (`-display gtk,gl=on,zoom-to-fit=on`) with `ramfb` and `virtio-gpu-gl-pci,hostmem=4G,blob=true` | PipeWire (`-audiodev pipewire`) |
| `aarch64-darwin` (Apple Silicon) | `qemu-system-aarch64` with Hypervisor.framework (`accel=hvf`), `virt`, 8 GB RAM | Cocoa (`-display cocoa`) with `ramfb` and `virtio-gpu-pci` | CoreAudio (`-audiodev coreaudio`) |

### Apple Silicon (`aarch64-darwin`) with `linux-builder`

On Apple Silicon macOS, `vm-retro` runs natively on macOS with Hypervisor.framework (`hvf`), Cocoa display output, and CoreAudio. To build the `aarch64-linux` NixOS disk image, ISO, or OTA bundle on macOS, enable a Linux remote builder (`linux-builder`). You can use the `linux-builder` included with Determinate Nix or `nix-darwin`. Once `linux-builder` is active, `just boot-disk` and `just boot-iso` build the `aarch64-linux` image on the builder and boot it in native macOS QEMU.

### Control the VM and copy files

`vm-retro` forwards host TCP port `2222` to Secure Shell (SSH) port `22` on the guest. You can also shut down or terminate the active VM from another terminal.

```bash
# Copy ROM sets into the running VM over SSH
rsync -avP -e "ssh -p 2222" ./roms/ ludo@localhost:/storage/Retro/roms/

# Send an ACPI powerdown signal to the running VM
just vm --shutdown

# Forcefully stop the running VM
just vm --kill
```

## Controller passthrough (evdev and USB)

`vm-retro` supports two controller passthrough methods so that you can test Ludo navigation and gameplay with physical gamepads:

1. **Automatic Linux `evdev` passthrough**: On Linux hosts (`x86_64-linux` and `aarch64-linux`), `vm-retro` scans `/dev/input/event*` at startup. Every readable event node where `udevadm info` reports `ID_INPUT_JOYSTICK=1` attaches automatically to the VM through `virtio-input-host-pci`.
2. **Explicit USB passthrough (`--usb-device VID:PID`)**: Pass `--usb-device VID:PID` on macOS or Linux to attach a Universal Serial Bus (USB) controller (`usb-host`). You can repeat this flag for multiple controllers.

```bash
# Pass an Xbox 360 controller (045e:028e) through to vm-retro
just vm --disk result-disk/extra-life.raw --usb-device 045e:028e

# Or invoke nix run directly with multiple USB devices
nix run .#vm-retro -- --disk result-disk/extra-life.raw --usb-device 045e:028e --usb-device 054c:0ce6
```
