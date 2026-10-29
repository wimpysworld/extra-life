import 'just/loader.just'

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

# Build the Extra Life GPT disk image (optionally for a specific SoC target)
build-disk target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    if [[ -z "${target}" ]]; then
        attr=".#disk-image"
        out_link="result-disk"
    else
        attr=".#nixosConfigurations.${target}.config.system.build.diskImage"
        out_link="result-disk-${target}"
    fi
    echo "Disk 󰋊 Building: ${attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${attr}" --out-link "${out_link}"
    else
        nix build "${attr}" --out-link "${out_link}"
    fi

# Build the Extra Life OTA update bundle (optionally for a specific SoC target)
build-ota target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    if [[ -z "${target}" ]]; then
        attr=".#ota-bundle"
        out_link="result-ota"
    else
        attr=".#nixosConfigurations.${target}.config.system.build.otaBundle"
        out_link="result-ota-${target}"
    fi
    echo "OTA 󰏗 Building: ${attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${attr}" --out-link "${out_link}"
    else
        nix build "${attr}" --out-link "${out_link}"
    fi

# Build the ISO and boot it in vm-retro
boot-iso: build-iso
    nix run .#vm-retro -- .vm/extra-life.iso

# Build the UEFI GPT disk image and boot it in vm-retro
boot-disk: build-disk
    #!/usr/bin/env bash
    set -euo pipefail
    disk_src=$(find -L result-disk -maxdepth 1 \( -name '*.raw*' -o -name '*.img*' \) | head -n 1)
    if [[ -z "${disk_src}" ]]; then
        echo "No disk image found under result-disk" >&2
        exit 1
    fi
    nix run .#vm-retro -- --disk "${disk_src}"

# Run or control vm-retro (--shutdown, --kill, --usb-device VID:PID)
vm *args:
    nix run .#vm-retro -- {{ args }}

# Provision the extralife-ota Cloudflare R2 bucket and custom domain via wrangler and sops
cf-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    secrets_file="secrets/secrets.yaml"
    if [[ ! -f "${secrets_file}" ]]; then
        echo "Error: ${secrets_file} not found" >&2
        exit 1
    fi
    echo "Cloudflare 󰅟 Provisioning R2 bucket and extralife-ota.wimpys.world"
    export CLOUDFLARE_ACCOUNT_ID
    export CLOUDFLARE_API_TOKEN
    CLOUDFLARE_ACCOUNT_ID="$(sops decrypt --extract '["cloudflare_account_id"]' "${secrets_file}")"
    CLOUDFLARE_API_TOKEN="$(sops decrypt --extract '["cloudflare_api_token"]' "${secrets_file}")"
    zone_id="$(sops decrypt --extract '["cloudflare_zone_id"]' "${secrets_file}")"
    wrangler r2 bucket create extralife-ota || true
    wrangler r2 bucket domain add extralife-ota --domain extralife-ota.wimpys.world --zone-id "${zone_id}" --force

# Build and publish the OTA update bundle and manifest to Cloudflare R2 via rclone and sops
publish-ota: build-ota
    #!/usr/bin/env bash
    set -euo pipefail
    secrets_file="secrets/secrets.yaml"
    if [[ ! -f "${secrets_file}" ]]; then
        echo "Error: ${secrets_file} not found" >&2
        exit 1
    fi
    echo "OTA 󰅟 Publishing result-ota to r2:extralife-ota"
    account_id="$(sops decrypt --extract '["cloudflare_account_id"]' "${secrets_file}")"
    export RCLONE_CONFIG_R2_TYPE="s3"
    export RCLONE_CONFIG_R2_PROVIDER="Cloudflare"
    export RCLONE_CONFIG_R2_REGION="auto"
    export RCLONE_CONFIG_R2_NO_CHECK_BUCKET="true"
    export RCLONE_CONFIG_R2_ENDPOINT="https://${account_id}.r2.cloudflarestorage.com"
    export RCLONE_CONFIG_R2_ACCESS_KEY_ID
    export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY
    RCLONE_CONFIG_R2_ACCESS_KEY_ID="$(sops decrypt --extract '["r2_access_key_id"]' "${secrets_file}")"
    RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$(sops decrypt --extract '["r2_secret_access_key"]' "${secrets_file}")"
    rclone copy --progress --s3-upload-cutoff 100M --s3-chunk-size 64M result-ota/ r2:extralife-ota/

# Stop vm-retro if running, delete VM disk and NVRAM state, and remove build links
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Clean 󰩹 Removing VM state and build links"
    nix run .#vm-retro -- --kill >/dev/null 2>&1 || true
    rm -rf .vm result result-*
