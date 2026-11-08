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
    printf "  %-10s %s\n" "rk3326"  "Rockchip RK3326 (Odroid Go Advance/Super, Anbernic RG351M/V, GameConsole R36S/R33S, Powkiddy RGB20S)"
    printf "  %-10s %s\n" "rk3566"  "Rockchip RK3566 (Anbernic RG353/RG503/RG ARC and Powkiddy RGB20 Pro/RGB20SX/RGB30/RK2023/RGB10MAX3/X35S/X55)"
    printf "  %-10s %s\n" "rk3588"  "Rockchip RK3588 / RK3588S (GameForce ACE, Orange Pi 5, Retro Lite CM5, RetroLED CM5)"
    printf "  %-10s %s\n" "sm6115"  "Qualcomm Snapdragon 662 (Mangmi Air X MQ65/MQ66/MQ66B and Mangmi Air Y)"
    printf "  %-10s %s\n" "sm6125"  "Qualcomm Snapdragon 665 (Retroid Pocket Duo Lite)"
    printf "  %-10s %s\n" "sm8250"  "Qualcomm Snapdragon 865 (Retroid Pocket 5, Pocket Flip 2, Pocket Mini/Mini V2, AYN Thor Lite, Mangmi Air Y Pro/Pocket Max)"
    printf "  %-10s %s\n" "sm8550"  "Qualcomm Snapdragon 8 Gen 2 (AYN Odin 2/Mini/Portal, AYN Thor, AYANEO Pocket ACE/DMG/DS/EVO/S, Retroid Pocket 6)"
    printf "  %-10s %s\n" "h700"    "Allwinner H700 (Anbernic RG28XX, RG34XX/SP, RG35XX Plus/H/SP/2024/Pro, RG40XX H/V, RG CubeXX)"
    echo ""

    echo "Device IDs (nixos/devices/devices.toml):"
    printf "  %-22s %-10s %-14s %-7s %s\n" "DEVICE ID" "VARIANT" "ARCH" "DEBUG" "DESCRIPTION"
    printf "  %-22s %-10s %-14s %-7s %s\n" "---------" "-------" "----" "-----" "-----------"
    jq -r '
      .devices
      | to_entries
      | sort_by(.value.soc, .key)
      | .[]
      | [.key, .value.soc, .value.arch, (if .value.debug then "on" else "off" end), .value.name]
      | @tsv
    ' <<< "${catalogue}" | while IFS=$'\t' read -r id soc arch debug name; do
        printf "  %-22s %-10s %-14s %-7s %s\n" "${id}" "${soc}" "${arch}" "${debug}" "${name}"
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

# Build a family's native kernel, initrd, system closure, and all published disk images
build-family soc system="":
    #!/usr/bin/env bash
    set -euo pipefail
    soc={{ quote(soc) }}
    system={{ quote(system) }}
    if [[ -z "${system}" ]]; then
        system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
    fi
    case "${system}" in
        x86_64-linux|aarch64-linux) ;;
        *) echo "Unsupported package system: ${system}" >&2; exit 1 ;;
    esac

    catalogue="$(nix eval --impure --json --expr 'builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')"
    configurations="$(nix eval --no-update-lock-file .#nixosConfigurations --apply builtins.attrNames --json)"
    packages="$(nix eval --no-update-lock-file ".#packages.${system}" --apply builtins.attrNames --json)"
    images="$(jq -er --arg soc "${soc}" --argjson catalogue "${catalogue}" --argjson configurations "${configurations}" '
      ($configurations | map(select(endswith("-appliance")) | rtrimstr("-appliance"))) as $families
      | if ($families | index($soc)) == null then
          error("Unknown SoC family: \($soc)")
        else . end
      | map(
          select(startswith("disk-image-"))
          | . as $attr
          | ltrimstr("disk-image-") as $id
          | (if ($families | index($id)) != null then $id
             else $catalogue.devices[$id].soc // error("Unmapped disk image: \($attr)")
             end) as $family
          | if ($families | index($family)) == null then
              error("Unknown family for disk image: \($attr)")
            else {attr: $attr, soc: $family} end
        )
      | if any(.[]; .attr == ("disk-image-" + $soc)) then .
        else error("Missing family disk image: \($soc)") end
      | .[] | select(.soc == $soc) | .attr
    ' <<< "${packages}")"

    family_system="$(nix eval --no-update-lock-file ".#nixosConfigurations.${soc}.config.nixpkgs.hostPlatform.system" --raw)"
    if [[ "${system}" != "${family_system}" ]]; then
        echo "Unsupported package system ${system} for ${soc}: build-family requires ${family_system}. Cross-image kernel, initrd, and toplevel targets are not exposed by the flake." >&2
        exit 1
    fi

    targets=(
        ".#nixosConfigurations.${soc}.config.system.build.kernel"
        ".#nixosConfigurations.${soc}.config.system.build.initialRamdisk"
        ".#nixosConfigurations.${soc}.config.system.build.toplevel"
    )
    while IFS= read -r image; do
        targets+=(".#packages.${system}.${image}")
    done <<< "${images}"
    printf 'Building %s\n' "${targets[@]}"
    nix build --no-link --no-update-lock-file --keep-going -L --json "${targets[@]}"

# Build every appliance family with its native Linux package system
build-world logs="dist/build-world":
    #!/usr/bin/env bash
    set -Eeuo pipefail
    trap 'code=$?; printf "build-world: setup or log operation failed (exit %s).\n" "${code}" >&2; exit "${code}"' ERR
    logs={{ quote(logs) }}
    if [[ -z "${logs}" || "${logs}" == *$'\t'* || "${logs}" == *$'\n'* || "${logs}" == *$'\r'* ]]; then
        echo "build-world: logs must be a non-empty path without tabs or line breaks." >&2
        exit 1
    fi
    mkdir -p -- "${logs}"
    run_dir="$(mktemp -d -- "${logs}/run.XXXXXXXXXX")"
    summary="${run_dir}/summary.tsv"
    printf 'family\tsystem\tstage\tstatus\texit_code\tlog\n' > "${summary}"
    trap 'code=$?; printf "Summary: %s\n" "${summary}"; cat -- "${summary}"; exit "${code}"' EXIT
    discovery_log="${run_dir}/discovery.log"
    exec 3>>"${discovery_log}"
    printf 'Discovery log: %s\n' "${discovery_log}"
    if version="$(nix --version 2>&3)"; then
        printf '%s\n' "${version}" >&3
    else
        code=$?
        printf '%s\n' "${version}" >&3
        printf 'build-world: Nix version check failed. See %s\n' "${discovery_log}" >&2
        exit "${code}"
    fi
    if [[ "${version}" != 'nix (Determinate Nix '*') '* ]]; then
        echo "build-world: Determinate Nix is required. The installed Nix will not be changed." >&2
        exit 1
    fi
    if configurations="$(nix eval --no-update-lock-file .#nixosConfigurations --apply builtins.attrNames --json 2>&3)"; then
        code=0
    else
        code=$?
    fi
    printf '%s\n' "${configurations}" >&3
    if (( code != 0 )); then
        printf 'build-world: family discovery failed. See %s\n' "${discovery_log}" >&2
        exit "${code}"
    fi
    if families="$(jq -ers '
      if length != 1 then error("Expected one configuration array") else .[0] end
      | if type != "array" then error("Expected a configuration array") else . end
      | if all(.[]; type == "string") then . else error("Expected configuration names") end
      | map(select(endswith("-appliance")) | rtrimstr("-appliance"))
      | if all(.[]; test("\\A[A-Za-z0-9_][A-Za-z0-9_-]*\\z")) then . else error("Invalid family name") end
      | unique
      | if length > 0 then .[] else error("No appliance families found") end
    ' <<< "${configurations}" 2>&3)"; then
        printf 'Families:\n%s\n' "${families}" >&3
    else
        code=$?
        printf 'build-world: invalid or empty family discovery. See %s\n' "${discovery_log}" >&2
        exit "${code}"
    fi
    result=0
    while IFS= read -r family; do
        log="${run_dir}/${family}.log"
        exec 3>>"${log}"
        printf 'Resolving %s. Log: %s\n' "${family}" "${log}"
        stage=system
        code=0
        if system="$(nix eval --no-update-lock-file ".#nixosConfigurations.${family}.config.nixpkgs.hostPlatform.system" --raw 2>&3)"; then
            printf '%s\n' "${system}" >&3
            case "${system}" in
                x86_64-linux|aarch64-linux) ;;
                *) printf 'Unsupported package system: %s\n' "${system}" >&3; system=-; code=1 ;;
            esac
        else
            code=$?
            printf '%s\n' "${system}" >&3
            system=-
        fi
        if (( code == 0 )); then
            stage=build
            printf 'Building %s (%s). Log: %s\n' "${family}" "${system}" "${log}"
            if just --quiet build-family "${family}" "${system}" >&3 2>&1; then
                code=0
            else
                code=$?
            fi
        fi
        status=ok
        if (( code != 0 )); then
            status=failed
            result=1
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${family}" "${system}" "${stage}" "${status}" "${code}" "${log}" >> "${summary}"
        printf '%s: %s at %s (exit %s). Log: %s\n' "${family}" "${status}" "${stage}" "${code}" "${log}"
    done <<< "${families}"
    exit "${result}"

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

_disk-attr target variant:
    #!/usr/bin/env bash
    set -euo pipefail
    case {{ quote(target) }} in
        anbernic-rg35xx-plus|anbernic-rg35xx-2024|anbernic-rg35xx-pro|anbernic-rg35xx-h|anbernic-rg35xx-sp|anbernic-rg40xx-h|anbernic-rg40xx-v|anbernic-rg-cubexx|anbernic-rg28xx|anbernic-rg34xx|anbernic-rg34xx-sp|hardkernel-odroid-go-advance|hardkernel-odroid-go-super|anbernic-rg351m|anbernic-rg351v|gameconsole-r33s|gameconsole-r36s|powkiddy-rgb20s|powkiddy-rgb20sx|powkiddy-x35s|powkiddy-x55|gameforce-ace|orangepi-5|retro-lite-cm5|retroled-cm5)
            printf '.#disk-image-%s\n' {{ quote(target) }}
            ;;
        *)
            printf '.#disk-image-%s\n' {{ quote(variant) }}
            ;;
    esac

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
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3326|rk3566|rk3588|sm6115|sm6125|sm8250|sm8550|h700)
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
        attr="$(just --quiet _disk-attr "${target}" "${variant}")"
        if [[ "${attr}" != ".#disk-image-${variant}" ]]; then
            out_link="result-disk-${target}"
        else
            out_link="result-disk-${variant}"
        fi
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
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3326|rk3566|rk3588|sm6115|sm6125|sm8250|sm8550|h700)
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
    attr=".#ota-bundle-${variant}"
    echo "OTA 󰏗 Building: ${attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${attr}" --out-link "${out_link}"
    else
        nix build "${attr}" --out-link "${out_link}"
    fi

    version="$(tr -d '[:space:]' < VERSION)"
    dist_dir="dist/v${version}/${variant}"
    mkdir -p "${dist_dir}"
    tar_name="extra-life-${variant}-${version}.tar.zst"
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
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3326|rk3566|rk3588|sm6115|sm6125|sm8250|sm8550|h700)
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

    disk_attr=".#disk-image-${variant}"
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
    img_xz="extra-life-${variant}-${version}.img.xz"
    rm -f "${dist_dir}"/*.img.zst "${dist_dir}"/*.img.zst.sha256
    echo "Disk 󰋊 Compressing: ${dist_dir}/${img_xz}"
    xz -T0 -6 -f -c "${disk_src}" > "${dist_dir}/${img_xz}"
    chmod 0644 "${dist_dir}/${img_xz}"
    img_sha256="$(sha256sum "${dist_dir}/${img_xz}" | cut -d' ' -f1)"
    printf '%s  %s\n' "${img_sha256}" "${img_xz}" > "${dist_dir}/${img_xz}.sha256"
    chmod 0644 "${dist_dir}/${img_xz}.sha256"

    if [[ -n "${target}" ]]; then
        target_disk_attr="$(just --quiet _disk-attr "${target}" "${variant}")"
        if [[ "${target_disk_attr}" != "${disk_attr}" ]]; then
            target_disk_link="result-disk-${target}"
            echo "Disk 󰋊 Building: ${target_disk_attr}"
            if command -v nom >/dev/null 2>&1; then
                nom build "${target_disk_attr}" --out-link "${target_disk_link}"
            else
                nix build "${target_disk_attr}" --out-link "${target_disk_link}"
            fi
            target_disk_src="$(find -L "${target_disk_link}" -maxdepth 1 \( -name '*.raw*' -o -name '*.img*' \) | head -n 1)"
            if [[ -z "${target_disk_src}" ]]; then
                echo "No disk image found under ${target_disk_link}" >&2
                exit 1
            fi
            target_img_xz="extra-life-${target}-${version}.img.xz"
            echo "Disk 󰋊 Compressing: ${dist_dir}/${target_img_xz}"
            xz -T0 -6 -f -c "${target_disk_src}" > "${dist_dir}/${target_img_xz}"
            chmod 0644 "${dist_dir}/${target_img_xz}"
            target_img_sha256="$(sha256sum "${dist_dir}/${target_img_xz}" | cut -d' ' -f1)"
            printf '%s  %s\n' "${target_img_sha256}" "${target_img_xz}" > "${dist_dir}/${target_img_xz}.sha256"
            chmod 0644 "${dist_dir}/${target_img_xz}.sha256"
        fi
    fi

    ota_attr=".#ota-bundle-${variant}"
    ota_link="result-ota-${variant}"
    echo "OTA 󰏗 Building: ${ota_attr}"
    if command -v nom >/dev/null 2>&1; then
        nom build "${ota_attr}" --out-link "${ota_link}"
    else
        nix build "${ota_attr}" --out-link "${ota_link}"
    fi
    tar_name="extra-life-${variant}-${version}.tar.zst"
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
      --arg img_name "${img_xz}" \
      --arg img_sha256 "${img_sha256}" \
      --arg img_url "https://extralife-ota.wimpys.world/v${version}/${variant}/${img_xz}" \
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
            x86_64|aarch64|rpi02w|rpi4|rpi5|rk3326|rk3566|rk3588|sm6115|sm6125|sm8250|sm8550|h700)
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
