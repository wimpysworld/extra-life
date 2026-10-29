import 'just/loader.just'

# List recipes
default:
    @just --list --unsorted

# List supported SoC variant IDs, board IDs, and case IDs
devices:
    #!/usr/bin/env bash
    set -euo pipefail
    catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"

    echo "SoC Variant IDs (VARIANT_ID):"
    printf "  %-10s %s\n" "VARIANT" "DESCRIPTION"
    printf "  %-10s %s\n" "-------" "-----------"
    printf "  %-10s %s\n" "x86_64"  "Generic 64-bit PC, UEFI VM, and GPD WIN handhelds"
    printf "  %-10s %s\n" "aarch64" "Generic 64-bit ARM UEFI and Apple Silicon / Linux VM"
    printf "  %-10s %s\n" "rpi02w"  "Broadcom BCM2710 (Raspberry Pi Zero 2 W, Pi 3B/3B+/3A+, CM3)"
    printf "  %-10s %s\n" "rpi4"    "Broadcom BCM2711 (Raspberry Pi 4B, Pi 400, CM4, CM4S)"
    printf "  %-10s %s\n" "rpi5"    "Broadcom BCM2712 (Raspberry Pi 5, Pi 500, CM5)"
    printf "  %-10s %s\n" "rk3566"  "Rockchip RK3566 (Anbernic RG353/RG503/RG ARC and Powkiddy RGB30/RK2023/RGB10MAX3)"
    printf "  %-10s %s\n" "sm6115"  "Qualcomm Snapdragon 662 (Mangmi Air X MQ65/MQ66/MQ66B and Mangmi Air Y)"
    echo ""

    echo "Device IDs (nixos/devices/devices.toml):"
    printf "  %-22s %-10s %-14s %s\n" "DEVICE ID" "VARIANT" "ARCH" "DESCRIPTION"
    printf "  %-22s %-10s %-14s %s\n" "---------" "-------" "----" "-----------"
    jq -r '
      .devices
      | to_entries
      | sort_by(.value.soc, .key)
      | .[]
      | [.key, .value.soc, .value.arch, .value.name]
      | @tsv
    ' <<< "${catalogue}" | while IFS=$'\t' read -r id soc arch name; do
        printf "  %-22s %-10s %-14s %s\n" "${id}" "${soc}" "${arch}" "${name}"
    done
    echo ""

    echo "Case IDs (nixos/devices/devices.toml):"
    printf "  %-22s %-20s %-14s %s\n" "CASE ID" "COMPATIBLE VARIANTS" "CASE OPTION" "DESCRIPTION"
    printf "  %-22s %-20s %-14s %s\n" "-------" "-------------------" "-----------" "-----------"
    jq -r '
      .cases
      | to_entries
      | sort_by(.key)
      | .[]
      | [.key, (.value.socs | join(", ")), .value.profile, .value.name]
      | @tsv
    ' <<< "${catalogue}" | while IFS=$'\t' read -r id socs profile name; do
        printf "  %-22s %-20s %-14s %s\n" "${id}" "${socs}" "${profile}" "${name}"
    done

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

# Build the Extra Life GPT disk image (optionally for a specific device or SoC target)
build-disk target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    if [[ -z "${target}" ]]; then
        attr=".#disk-image"
        out_link="result-disk"
    else
        case "${target}" in
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3566|sm6115)
                variant="${target}"
                ;;
            *)
                catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"
                variant="$(jq -r --arg t "${target}" '.devices[$t].soc // empty' <<< "${catalogue}")"
                if [[ -z "${variant}" ]]; then
                    echo "Error: unknown target '${target}'. Run 'just devices' to list supported SoC variants and device IDs." >&2
                    exit 1
                fi
                echo "Resolved device '${target}' -> variant '${variant}'"
                ;;
        esac
        attr=".#nixosConfigurations.${variant}.config.system.build.diskImage"
        out_link="result-disk-${variant}"
    fi
    echo "Disk 󰋊 Building: ${attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${attr}" --out-link "${out_link}"
    else
        nix build "${attr}" --out-link "${out_link}"
    fi

# Build the Extra Life OTA update bundle (optionally for a specific device or SoC target)
build-ota target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    if [[ -z "${target}" ]]; then
        system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
        if [[ "${system}" == aarch64-* ]]; then
            variant="aarch64"
        else
            variant="x86_64"
        fi
        out_link="result-ota"
    else
        case "${target}" in
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3566|sm6115)
                variant="${target}"
                ;;
            *)
                catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"
                variant="$(jq -r --arg t "${target}" '.devices[$t].soc // empty' <<< "${catalogue}")"
                if [[ -z "${variant}" ]]; then
                    echo "Error: unknown target '${target}'. Run 'just devices' to list supported SoC variants and device IDs." >&2
                    exit 1
                fi
                echo "Resolved device '${target}' -> variant '${variant}'"
                ;;
        esac
        out_link="result-ota-${variant}"
    fi
    attr=".#nixosConfigurations.${variant}.config.system.build.otaBundle"
    echo "OTA 󰏗 Building: ${attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${attr}" --out-link "${out_link}"
    else
        nix build "${attr}" --out-link "${out_link}"
    fi

    version="$(tr -d '[:space:]' < VERSION)"
    dist_dir="dist/v${version}/${variant}"
    mkdir -p "${dist_dir}"
    tar_name="extra-life-${variant}-${version}.tar"
    cp -f "${out_link}/${tar_name}" "${dist_dir}/${tar_name}"
    cp -f "${out_link}/${tar_name}.sha256" "${dist_dir}/${tar_name}.sha256"
    cp -f "${out_link}/meta.json" "${dist_dir}/meta.json"
    chmod 0644 "${dist_dir}/${tar_name}" "${dist_dir}/${tar_name}.sha256" "${dist_dir}/meta.json"

    shopt -s nullglob
    meta_files=(dist/v*/*/meta.json)
    jq -s '
      group_by(.version)
      | map({
          name: .[0].version,
          assets: (map(.asset) | unique_by(.device) | sort_by(.device))
        })
      | sort_by(.name)
      | reverse
    ' "${meta_files[@]}" > dist/releases.json

# Build all artefacts (disk image, OTA bundle, and ISO if applicable) for a device or SoC variant into dist/
build-device target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    if [[ -z "${target}" ]]; then
        system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
        if [[ "${system}" == aarch64-* ]]; then
            variant="aarch64"
        else
            variant="x86_64"
        fi
    else
        case "${target}" in
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3566|sm6115)
                variant="${target}"
                ;;
            *)
                catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"
                variant="$(jq -r --arg t "${target}" '.devices[$t].soc // empty' <<< "${catalogue}")"
                if [[ -z "${variant}" ]]; then
                    echo "Error: unknown target '${target}'. Run 'just devices' to list supported SoC variants and device IDs." >&2
                    exit 1
                fi
                echo "Resolved device '${target}' -> variant '${variant}'"
                ;;
        esac
    fi

    version="$(tr -d '[:space:]' < VERSION)"
    dist_dir="dist/v${version}/${variant}"
    mkdir -p "${dist_dir}"

    disk_attr=".#nixosConfigurations.${variant}.config.system.build.diskImage"
    disk_link="result-disk-${variant}"
    echo "Disk 󰋊 Building: ${disk_attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${disk_attr}" --out-link "${disk_link}"
    else
        nix build "${disk_attr}" --out-link "${disk_link}"
    fi
    disk_src="$(find -L "${disk_link}" -maxdepth 1 \( -name '*.raw*' -o -name '*.img*' \) | head -n 1)"
    if [[ -z "${disk_src}" ]]; then
        echo "No disk image found under ${disk_link}" >&2
        exit 1
    fi
    img_zst="extra-life-${variant}-${version}.img.zst"
    echo "Disk 󰋊 Compressing: ${dist_dir}/${img_zst}"
    zstd -T0 -19 -f "${disk_src}" -o "${dist_dir}/${img_zst}"
    chmod 0644 "${dist_dir}/${img_zst}"
    img_sha256="$(sha256sum "${dist_dir}/${img_zst}" | cut -d' ' -f1)"
    printf '%s  %s\n' "${img_sha256}" "${img_zst}" > "${dist_dir}/${img_zst}.sha256"
    chmod 0644 "${dist_dir}/${img_zst}.sha256"

    ota_attr=".#nixosConfigurations.${variant}.config.system.build.otaBundle"
    ota_link="result-ota-${variant}"
    echo "OTA 󰏗 Building: ${ota_attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${ota_attr}" --out-link "${ota_link}"
    else
        nix build "${ota_attr}" --out-link "${ota_link}"
    fi
    tar_name="extra-life-${variant}-${version}.tar"
    cp -f "${ota_link}/${tar_name}" "${dist_dir}/${tar_name}"
    cp -f "${ota_link}/${tar_name}.sha256" "${dist_dir}/${tar_name}.sha256"
    chmod 0644 "${dist_dir}/${tar_name}" "${dist_dir}/${tar_name}.sha256"
    tar_sha256="$(cut -d' ' -f1 "${dist_dir}/${tar_name}.sha256")"

    jq -n \
      --arg version "v${version}" \
      --arg variant "${variant}" \
      --arg tar_name "${tar_name}" \
      --arg tar_sha256 "${tar_sha256}" \
      --arg tar_url "https://extralife-ota.wimpys.world/v${version}/${variant}/${tar_name}" \
      --arg img_name "${img_zst}" \
      --arg img_sha256 "${img_sha256}" \
      --arg img_url "https://extralife-ota.wimpys.world/v${version}/${variant}/${img_zst}" \
      '{
        version: $version,
        variant: $variant,
        asset: {
          name: $tar_name,
          device: $variant,
          sha256: $tar_sha256,
          browser_download_url: $tar_url
        },
        disk_image: {
          name: $img_name,
          sha256: $img_sha256,
          browser_download_url: $img_url
        }
      }' > "${dist_dir}/meta.json"
    chmod 0644 "${dist_dir}/meta.json"

    if [[ "${variant}" == "x86_64" || "${variant}" == "aarch64" ]]; then
        iso_attr=".#nixosConfigurations.${variant}-installer.config.system.build.isoImage"
        iso_link="result-iso-${variant}"
        echo "ISO 󰗮 Building: ${iso_attr}"
        if command -v nom >/dev/null 2>&1; then
            nom build "${iso_attr}" --out-link "${iso_link}"
        else
            nix build "${iso_attr}" --out-link "${iso_link}"
        fi
        iso_src="$(find -L "${iso_link}/iso" -maxdepth 1 -name '*.iso*' | head -n 1)"
        iso_name="extra-life-${variant}-${version}.iso"
        cp -f "${iso_src}" "${dist_dir}/${iso_name}"
        chmod 0644 "${dist_dir}/${iso_name}"
        iso_sha256="$(sha256sum "${dist_dir}/${iso_name}" | cut -d' ' -f1)"
        printf '%s  %s\n' "${iso_sha256}" "${iso_name}" > "${dist_dir}/${iso_name}.sha256"
        chmod 0644 "${dist_dir}/${iso_name}.sha256"
    fi

    shopt -s nullglob
    meta_files=(dist/v*/*/meta.json)
    jq -s '
      group_by(.version)
      | map({
          name: .[0].version,
          assets: (map(.asset) | unique_by(.device) | sort_by(.device))
        })
      | sort_by(.name)
      | reverse
    ' "${meta_files[@]}" > dist/releases.json
    echo "Device 󰸞 Staged artefacts in ${dist_dir}/ and updated dist/releases.json"

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

# Publish staged dist/ artefacts and merged releases.json to Cloudflare R2
publish-ota target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target={{ quote(target) }}
    version="$(tr -d '[:space:]' < VERSION)"
    variant=""

    if [[ -n "${target}" ]]; then
        case "${target}" in
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3566|sm6115)
                variant="${target}"
                ;;
            *)
                catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"
                variant="$(jq -r --arg t "${target}" '.devices[$t].soc // empty' <<< "${catalogue}")"
                if [[ -z "${variant}" ]]; then
                    echo "Error: unknown target '${target}'. Run 'just devices' to list supported SoC variants and device IDs." >&2
                    exit 1
                fi
                echo "Resolved device '${target}' -> variant '${variant}'"
                ;;
        esac
        if [[ ! -f "dist/v${version}/${variant}/meta.json" ]]; then
            just build-device "${variant}"
        fi
    else
        shopt -s nullglob
        existing_meta=(dist/v*/*/meta.json)
        if (( ${#existing_meta[@]} == 0 )); then
            just build-device
        fi
    fi

    secrets_file="secrets/secrets.yaml"
    if [[ ! -f "${secrets_file}" ]]; then
        echo "Error: ${secrets_file} not found" >&2
        exit 1
    fi
    echo "OTA 󰅟 Publishing staged dist/ artefacts to r2:extralife-ota"
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

    tmp_remote="$(mktemp)"
    trap 'rm -f "${tmp_remote}"' EXIT
    rclone copyto r2:extralife-ota/releases.json "${tmp_remote}" 2>/dev/null || echo '[]' > "${tmp_remote}"
    if [[ ! -s "${tmp_remote}" ]]; then
        echo '[]' > "${tmp_remote}"
    fi

    shopt -s nullglob
    meta_files=(dist/v*/*/meta.json)
    jq -s --slurpfile remote "${tmp_remote}" '
      (
        [ $remote[0][]? | .name as $ver | .assets[]? | { version: $ver, asset: . } ]
        + [ .[] | { version: .version, asset: .asset } ]
      )
      | group_by(.version)
      | map({
          name: .[0].version,
          assets: (
            reduce .[] as $item ({}; .[$item.asset.device] = $item.asset)
            | [ .[] ]
            | sort_by(.device)
          )
        })
      | sort_by(.name)
      | reverse
    ' "${meta_files[@]}" > dist/releases.json

    if [[ -n "${variant}" ]]; then
        rclone copy --progress --s3-upload-cutoff 100M --s3-chunk-size 64M "dist/v${version}/${variant}/" "r2:extralife-ota/v${version}/${variant}/"
    else
        for vdir in dist/v*; do
            if [[ -d "${vdir}" ]]; then
                vname="$(basename "${vdir}")"
                rclone copy --progress --s3-upload-cutoff 100M --s3-chunk-size 64M "${vdir}/" "r2:extralife-ota/${vname}/"
            fi
        done
    fi
    rclone copyto --progress dist/releases.json r2:extralife-ota/releases.json

# Stop vm-retro if running, delete VM disk and NVRAM state, and remove build links and dist/
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Clean 󰩹 Removing VM state, build links, and dist/"
    nix run .#vm-retro -- --kill >/dev/null 2>&1 || true
    rm -rf .vm result result-* dist
