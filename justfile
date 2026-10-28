# List recipes
default:
    @just --list --unsorted

# Evaluate flake configurations and per-system outputs
check:
    #!/usr/bin/env bash
    set -euo pipefail
    system=$(nix eval --impure --raw --expr 'builtins.currentSystem')
    echo "Flake 󱄅 Check: ${system}"

    echo "󱄅 NixOS configurations:"
    for config in $(nix eval .#nixosConfigurations --apply builtins.attrNames --json | jq -r '.[]'); do
        echo "    Checking nixosConfigurations.${config}..."
        nix eval ".#nixosConfigurations.${config}.config.system.build.toplevel.drvPath" --raw >/dev/null
    done

    echo "󰏗 Per-system outputs (${system}):"
    nix eval ".#formatter.${system}.drvPath" --raw >/dev/null
    for pkg in $(nix eval ".#packages.${system}" --apply builtins.attrNames --json | jq -r '.[]'); do
        echo "    Checking packages.${system}.${pkg}..."
        nix eval ".#packages.${system}.${pkg}.drvPath" --raw >/dev/null
    done

    echo "󰸞 Flake check passed for ${system}"

# Format Nix files
fmt *paths:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ $# -eq 0 ]; then
        echo "Nix 󰉼 Formatting: all files"
        if command -v deadnix >/dev/null 2>&1; then
            deadnix --no-lambda-pattern-names --edit .
        fi
        if command -v statix >/dev/null 2>&1; then
            statix fix .
        fi
        nix fmt
    else
        echo "Nix 󰉼 Formatting: $*"
        if command -v deadnix >/dev/null 2>&1; then
            deadnix --no-lambda-pattern-names --edit "$@"
        fi
        if command -v statix >/dev/null 2>&1; then
            for target in "$@"; do
                statix fix "$target"
            done
        fi
        nix fmt -- "$@"
    fi

# Update flake inputs or refresh the lock file
update input="" lock_only="false" override_url="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ {{ quote(lock_only) }} != "true" && {{ quote(lock_only) }} != "false" ]]; then
        echo "lock_only must be true or false" >&2
        exit 1
    fi
    if [[ -n {{ quote(override_url) }} && ( {{ quote(lock_only) }} != "true" || -z {{ quote(input) }} ) ]]; then
        echo "override_url requires lock_only=true and an input" >&2
        exit 1
    fi
    if [[ {{ quote(lock_only) }} == "true" && -n {{ quote(input) }} && -z {{ quote(override_url) }} ]]; then
        echo "lock_only with an input requires override_url" >&2
        exit 1
    fi
    echo "flake.lock 󰈡 Updating"
    if [[ -n {{ quote(override_url) }} ]]; then
        nix flake lock --override-input {{ quote(input) }} {{ quote(override_url) }}
    elif [[ {{ quote(lock_only) }} == "true" ]]; then
        nix flake lock
    elif [[ -n {{ quote(input) }} ]]; then
        nix flake update {{ quote(input) }}
    else
        nix flake update
    fi

# Build a specific package from the flake
build-pkg pkg="ludo":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "{{ pkg }} 󰏗 Building: .#{{ pkg }}"
    if command -v nom >/dev/null 2>&1; then
        nom build ".#{{ pkg }}" --out-link "result-{{ pkg }}"
    else
        nix build ".#{{ pkg }}" --out-link "result-{{ pkg }}"
    fi

# Build the live bootable Extra Life ISO image
build-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "ISO 󰗮 Building: .#iso"
    if command -v nom >/dev/null 2>&1; then
        nom build .#iso --out-link result-iso
    else
        nix build .#iso --out-link result-iso
    fi
    mkdir -p .vm
    iso_src=$(find -L result-iso/iso -maxdepth 1 -name '*.iso*' | head -n 1)
    cp -f "${iso_src}" .vm/extra-life.iso
    chmod 644 .vm/extra-life.iso

# Build the Extra Life UEFI GPT disk image
build-disk:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Disk 󰋊 Building: .#disk-image"
    if command -v nom >/dev/null 2>&1; then
        nom build .#disk-image --out-link result-disk
    else
        nix build .#disk-image --out-link result-disk
    fi

# Build the ISO and boot it in vm-retro
boot-iso: build-iso
    nix run .#vm-retro -- .vm/extra-life.iso

# Build the UEFI GPT disk image and boot it in vm-retro
boot-disk: build-disk
    #!/usr/bin/env bash
    set -euo pipefail
    disk_src=$(find -L result-disk -maxdepth 1 -name '*.img*' | head -n 1)
    if [[ -z "${disk_src}" ]]; then
        echo "No disk image found under result-disk" >&2
        exit 1
    fi
    nix run .#vm-retro -- --disk "${disk_src}"

# Run or control vm-retro (--shutdown, --kill, --usb-device VID:PID)
vm *args:
    nix run .#vm-retro -- {{ args }}

# Stop vm-retro if running, delete VM disk and NVRAM state, and remove build links
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Clean 󰩹 Removing VM state and build links"
    nix run .#vm-retro -- --kill >/dev/null 2>&1 || true
    rm -rf .vm result result-*
