#!/usr/bin/env bash
set -euo pipefail

repo="$(pwd)"
real_just="$(command -v just)"
sandbox="$(mktemp -d)"
trap 'rm -rf -- "${sandbox}"' EXIT
mkdir -p "${sandbox}/bin" "${sandbox}/work"
export TEST_ROOT="${sandbox}" TEST_REPO="${repo}" TEST_JUST="${real_just}"
# Shell startup hooks must not replace the mocked command path.
unset BASH_ENV ENV
export PATH="${sandbox}/bin:${PATH}"

cat > "${sandbox}/bin/nix" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
    --version)
        echo version >> "${TEST_ROOT}/events"
        printf '%s\n' "${TEST_VERSION}"
        exit "${TEST_VERSION_CODE}"
        ;;
    'eval --no-update-lock-file .#nixosConfigurations --apply builtins.attrNames --json')
        echo discovery >> "${TEST_ROOT}/events"
        echo 'discovery stderr' >&2
        printf '%s\n' "${TEST_CONFIGURATIONS}"
        if [[ "${TEST_LOG_ERROR}" == yes ]]; then
            for run in "${TEST_LOGS}"/run.*; do
                mkdir "${run}/aarch64.log"
            done
        fi
        exit "${TEST_DISCOVERY_CODE}"
        ;;
    eval\ --no-update-lock-file\ .#nixosConfigurations.*.config.nixpkgs.hostPlatform.system\ --raw)
        family="${3#.#nixosConfigurations.}"
        family="${family%.config.nixpkgs.hostPlatform.system}"
        printf 'system\t%s\n' "${family}" >> "${TEST_ROOT}/events"
        printf 'system stderr: %s\n' "${family}" >&2
        if [[ "${family}" == "${TEST_EVAL_FAIL}" ]]; then
            echo 'partial system output'
            exit 23
        fi
        if [[ "${family}" == "${TEST_UNSUPPORTED}" ]]; then
            printf '%s' "${TEST_SYSTEM}"
        elif [[ "${family}" == x86_64 ]]; then
            printf x86_64-linux
        else
            printf aarch64-linux
        fi
        ;;
    'eval --impure --json --expr builtins.fromTOML (builtins.readFile ./nixos/devices/devices.toml)')
        printf '%s\n' '{"devices":{"board-one":{"soc":"h700"},"board-two":{"soc":"h700"},"board-three":{"soc":"rk3566"}}}'
        ;;
    eval\ --no-update-lock-file\ .#packages.*\ --apply\ builtins.attrNames\ --json)
        printf '%s\n' "${TEST_PACKAGES}"
        ;;
    build\ --no-link\ --no-update-lock-file\ --keep-going\ -L\ --json\ *)
        shift 6
        jq -cn --args '$ARGS.positional' -- "$@" >> "${TEST_ROOT}/targets"
        echo 'mock nix build stdout'
        echo 'mock nix build stderr' >&2
        if [[ "$1" == ".#nixosConfigurations.${TEST_NIX_FAIL}.config.system.build.kernel" ]]; then
            exit 37
        fi
        ;;
    *) printf 'Unexpected nix command: %s\n' "$*" >&2; exit 97 ;;
esac
MOCK

cat > "${sandbox}/bin/just" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 4 || "$1" != --quiet || "$2" != build-family ]]; then
    printf 'Unexpected just command: %s\n' "$*" >&2
    exit 98
fi
printf 'build\t%s\t%s\n' "$3" "$4" >> "${TEST_ROOT}/events"
printf 'build stdout: %s\n' "$3"
printf 'build stderr: %s\n' "$3" >&2
if [[ "$3" == "${TEST_BUILD_FAIL}" ]]; then
    exit 42
fi
if [[ "${TEST_DELEGATE}" == yes ]]; then
    exec "${TEST_JUST}" --justfile "${TEST_REPO}/justfile" --working-directory "${TEST_ROOT}/work" "$@"
fi
MOCK
chmod +x "${sandbox}/bin/nix" "${sandbox}/bin/just"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    cat "${sandbox}/output" >&2
    exit 1
}

equal() {
    [[ "$1" == "$2" ]] || fail "${3}: expected [$2], got [$1]"
}

contains() {
    grep -Fq -- "$2" "$1" || fail "${1} does not contain [$2]"
}

reset_case() {
    export TEST_VERSION='nix (Determinate Nix 3.4.2) 2.28.3' TEST_VERSION_CODE=0
    export TEST_CONFIGURATIONS='["x86_64-appliance","h700-appliance","aarch64-appliance"]'
    export TEST_DISCOVERY_CODE=0 TEST_EVAL_FAIL='' TEST_BUILD_FAIL=''
    export TEST_UNSUPPORTED='' TEST_SYSTEM='' TEST_DELEGATE=no TEST_LOG_ERROR=no TEST_NIX_FAIL=''
    export TEST_LOGS="${sandbox}/work/$1"
    : > "${sandbox}/events"
    : > "${sandbox}/targets"
    : > "${sandbox}/output"
}

run_world() {
    local expected="$1" actual=0
    shift
    "${real_just}" --justfile "${repo}/justfile" --working-directory "${sandbox}/work" --quiet build-world "$@" > "${sandbox}/output" 2>&1 || actual=$?
    equal "${actual}" "${expected}" 'recipe exit code'
}

read_summary() {
    local runs=("${TEST_LOGS}"/run.*/summary.tsv)
    equal "${#runs[@]}" 1 'summary count'
    summary="${runs[0]}"
    run_dir="${summary%/summary.tsv}"
    equal "$(head -n 1 "${summary}")" $'family\tsystem\tstage\tstatus\texit_code\tlog' 'summary header'
    contains "${sandbox}/output" "Summary: ${summary}"
    while IFS= read -r row; do
        contains "${sandbox}/output" "${row}"
    done < "${summary}"
}

row() {
    contains "${summary}" "$(printf '%s\t%s\t%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4" "$5" "${run_dir}/$1.log")"
}

reset_case "logs with spaces and 'quotes'"
families='["x86_64","sm8550","sm8250","sm6125","sm6115","rpi5","rpi4","rpi02w","rk3588","rk3566","rk3326","h700","aarch64","future-family"]'
TEST_CONFIGURATIONS="$(jq -cn --argjson families "${families}" '$families | map(. + "-appliance") + ["h700-appliance", "x86_64-installer", "h700", "unrelated"]')"
run_world 0 "${TEST_LOGS}"
read_summary
expected_events=$'version\ndiscovery'
while IFS= read -r family; do
    system=aarch64-linux
    [[ "${family}" != x86_64 ]] || system=x86_64-linux
    expected_events+="$(printf '\nsystem\t%s\nbuild\t%s\t%s' "${family}" "${family}" "${system}")"
    row "${family}" "${system}" build ok 0
    contains "${run_dir}/${family}.log" "system stderr: ${family}"
    contains "${run_dir}/${family}.log" "${system}"
    contains "${run_dir}/${family}.log" "build stdout: ${family}"
    contains "${run_dir}/${family}.log" "build stderr: ${family}"
done < <(jq -r 'sort[]' <<< "${families}")
equal "$(cat "${sandbox}/events")" "${expected_events}" 'sequential native builds and single discovery'
equal "$(wc -l < "${summary}" | tr -d ' ')" 15 'one row per unique family'
contains "${run_dir}/discovery.log" 'discovery stderr'
contains "${run_dir}/discovery.log" "${TEST_CONFIGURATIONS}"
first_summary="$(cat "${summary}")"
first_log="$(cat "${run_dir}/aarch64.log")"
run_world 0 "${TEST_LOGS}"
runs=("${TEST_LOGS}"/run.*/summary.tsv)
equal "${#runs[@]}" 2 'unique run directories'
equal "$(cat "${summary}")" "${first_summary}" 'prior summary unchanged'
equal "$(cat "${run_dir}/aarch64.log")" "${first_log}" 'prior family log unchanged'
echo 'PASS: dynamic families, native arguments, logs, spaces, and unique reruns'

reset_case failures
export TEST_EVAL_FAIL=aarch64 TEST_BUILD_FAIL=h700
run_world 1 "${TEST_LOGS}"
read_summary
row aarch64 - system failed 23
row h700 aarch64-linux build failed 42
row x86_64 x86_64-linux build ok 0
equal "$(cat "${sandbox}/events")" $'version\ndiscovery\nsystem\taarch64\nsystem\th700\nbuild\th700\taarch64-linux\nsystem\tx86_64\nbuild\tx86_64\tx86_64-linux' 'failure continuation'
contains "${run_dir}/aarch64.log" 'partial system output'
contains "${run_dir}/aarch64.log" 'system stderr: aarch64'
contains "${run_dir}/h700.log" 'build stderr: h700'
echo 'PASS: evaluation and build failures retain exact exit codes and continue'

for system in aarch64-darwin riscv64-linux '' $'aarch64-linux\ninjected\tvalue'; do
    reset_case "unsupported-${RANDOM}"
    export TEST_UNSUPPORTED=aarch64 TEST_SYSTEM="${system}"
    run_world 1 "${TEST_LOGS}"
    read_summary
    row aarch64 - system failed 1
    row h700 aarch64-linux build ok 0
    row x86_64 x86_64-linux build ok 0
    contains "${run_dir}/aarch64.log" 'Unsupported package system:'
    equal "$(wc -l < "${summary}" | tr -d ' ')" 4 'safe summary rows'
done
echo 'PASS: unsupported and malformed systems do not skip later families'

for configurations in '' '[]' '["x86_64-installer"]' '{"aarch64-appliance":true}' '[42]' 'null' 'broken json' '["-appliance"]' '["../bad-appliance"]' '["bad\nname-appliance"]' '["aarch64\n-appliance"]' '["bad\tname-appliance"]' '["aarch64-appliance"] []'; do
    reset_case "invalid-${RANDOM}"
    export TEST_CONFIGURATIONS="${configurations}"
    actual=0
    "${real_just}" --justfile "${repo}/justfile" --working-directory "${sandbox}/work" --quiet build-world "${TEST_LOGS}" > "${sandbox}/output" 2>&1 || actual=$?
    [[ "${actual}" != 0 ]] || fail 'invalid discovery succeeded'
    read_summary
    equal "$(cat "${sandbox}/events")" $'version\ndiscovery' 'no builds after invalid discovery'
    equal "$(wc -l < "${summary}" | tr -d ' ')" 1 'empty failure summary'
    contains "${sandbox}/output" 'invalid or empty family discovery'
done
reset_case discovery-error
export TEST_DISCOVERY_CODE=17
run_world 17 "${TEST_LOGS}"
read_summary
contains "${sandbox}/output" 'family discovery failed'
equal "$(cat "${sandbox}/events")" $'version\ndiscovery' 'no builds after discovery error'
echo 'PASS: invalid, empty, and failed discovery stop safely'

reset_case upstream
export TEST_VERSION='nix (Nix) 2.28.3'
run_world 1 "${TEST_LOGS}"
contains "${sandbox}/output" 'Determinate Nix is required'
equal "$(cat "${sandbox}/events")" version 'upstream Nix rejection before discovery'
reset_case version-error
export TEST_VERSION_CODE=19
run_world 19 "${TEST_LOGS}"
contains "${sandbox}/output" 'Nix version check failed'
equal "$(cat "${sandbox}/events")" version 'version error before discovery'
echo 'PASS: upstream Nix and failed version checks are rejected'

reset_case setup-error
printf occupied > "${TEST_LOGS}"
run_world 1 "${TEST_LOGS}"
contains "${sandbox}/output" 'setup or log operation failed'
equal "$(cat "${TEST_LOGS}")" occupied 'existing file preserved'
equal "$(cat "${sandbox}/events")" '' 'setup error before Nix'
reset_case log-error
export TEST_LOG_ERROR=yes
run_world 1 "${TEST_LOGS}"
contains "${sandbox}/output" 'setup or log operation failed'
equal "$(cat "${sandbox}/events")" $'version\ndiscovery' 'log error before family evaluation'
for logs in '' $'bad\tpath' $'bad\npath'; do
    reset_case bad-path
    run_world 1 "${logs}"
    contains "${sandbox}/output" 'logs must be a non-empty path'
    equal "$(cat "${sandbox}/events")" '' 'invalid log path before Nix'
done
echo 'PASS: setup, log, and invalid path errors fail clearly'

reset_case dist/build-world
cd "${sandbox}/work"
TEST_LOGS=dist/build-world
run_world 0
read_summary
row aarch64 aarch64-linux build ok 0
cd "${repo}"
echo 'PASS: default log directory'

reset_case delegated
export TEST_DELEGATE=yes TEST_PACKAGES
TEST_CONFIGURATIONS="$(jq -cn --argjson families "${families}" '$families | map(. + "-appliance")')"
TEST_PACKAGES="$(jq -cn --argjson families "${families}" '$families | map("disk-image-" + .) + ["disk-image-board-one", "disk-image-board-two", "disk-image-board-three", "iso", "ota-bundle-h700", "ludo"]')"
run_world 0 "${TEST_LOGS}"
read_summary
jq -s . "${sandbox}/targets" > "${sandbox}/actual-targets"
jq -n --argjson families "${families}" '
  $families | sort | map(
    . as $family
    | (if . == "x86_64" then "x86_64-linux" else "aarch64-linux" end) as $system
    | ["kernel", "initialRamdisk", "toplevel"]
    | map(".#nixosConfigurations." + $family + ".config.system.build." + .)
    + (["disk-image-" + $family]
       + (if $family == "h700" then ["disk-image-board-one", "disk-image-board-two"]
          elif $family == "rk3566" then ["disk-image-board-three"] else [] end)
       | map(".#packages." + $system + "." + .))
  )
' > "${sandbox}/expected-targets"
diff -u "${sandbox}/expected-targets" "${sandbox}/actual-targets" || fail 'build-family target coverage'
contains "${run_dir}/h700.log" 'mock nix build stdout'
contains "${run_dir}/h700.log" 'mock nix build stderr'
: > "${sandbox}/targets"
actual=0
"${real_just}" --justfile "${repo}/justfile" --working-directory "${sandbox}/work" --quiet build-family h700 x86_64-linux > "${sandbox}/output" 2>&1 || actual=$?
equal "${actual}" 1 'mixed native and cross-image rejection'
equal "$(cat "${sandbox}/targets")" '' 'no mixed-system build'
export TEST_NIX_FAIL=h700 TEST_LOGS="${sandbox}/work/delegated-failure"
run_world 1 "${TEST_LOGS}"
read_summary
row h700 aarch64-linux build failed 37
row x86_64 x86_64-linux build ok 0
echo 'PASS: unchanged build-family covers kernel, initrd, toplevel, and all family/device disk images only'
echo 'All mocked build tests passed.'
