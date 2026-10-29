{
  config,
  lib,
  pkgs,
  ...
}:
let
  deviceCatalogue = fromTOML (builtins.readFile ../../../devices/devices.toml);

  resolveCaseSnippet = ''
    case_id=${lib.escapeShellArg config.extraLife.case}

    if [[ -r /boot/case.txt ]]; then
      raw_case="$(grep -v '^[[:space:]]*#' /boot/case.txt | head -n 1 | tr -d '[:space:]')"
      if [[ -n "$raw_case" ]]; then
        case_id="$raw_case"
      fi
    elif [[ -r /storage/.config/extra-life-case ]]; then
      raw_case="$(grep -v '^[[:space:]]*#' /storage/.config/extra-life-case | head -n 1 | tr -d '[:space:]')"
      if [[ -n "$raw_case" ]]; then
        case_id="$raw_case"
      fi
    fi
  '';

  caseHelperScript = pkgs.writeShellScript "extra-life-case-helper" ''
    set -euo pipefail
    ${resolveCaseSnippet}

    case "$case_id" in
      none|"")
        exit 0
        ;;
      deskpi-pro)
        modprobe ch341 2>/dev/null || true
        while true; do
          if [[ -c /dev/ttyUSB0 ]]; then
            stty -F /dev/ttyUSB0 9600 raw -echo 2>/dev/null || true
            temp_milli=0
            if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
              temp_milli="$(< /sys/class/thermal/thermal_zone0/temp)"
            fi
            temp_c=$(( temp_milli / 1000 ))
            if (( temp_c >= 65 )); then
              printf 'pwm_100' > /dev/ttyUSB0 || true
            elif (( temp_c >= 55 )); then
              printf 'pwm_075' > /dev/ttyUSB0 || true
            elif (( temp_c >= 45 )); then
              printf 'pwm_050' > /dev/ttyUSB0 || true
            else
              printf 'pwm_000' > /dev/ttyUSB0 || true
            fi
          fi
          sleep 10
        done
        ;;
      argon-one)
        modprobe i2c-dev 2>/dev/null || true
        while true; do
          temp_milli=0
          if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
            temp_milli="$(< /sys/class/thermal/thermal_zone0/temp)"
          fi
          temp_c=$(( temp_milli / 1000 ))
          speed=0x00
          if (( temp_c >= 65 )); then
            speed=0x64
          elif (( temp_c >= 60 )); then
            speed=0x37
          elif (( temp_c >= 55 )); then
            speed=0x0a
          fi
          if command -v i2cset >/dev/null 2>&1 && [[ -c /dev/i2c-1 ]]; then
            i2cset -y 1 0x1a "$speed" 2>/dev/null || true
          fi
          sleep 10
        done
        ;;
      *)
        exit 0
        ;;
    esac
  '';

  caseStopScript = pkgs.writeShellScript "extra-life-case-stop" ''
    set -euo pipefail
    ${resolveCaseSnippet}

    case "$case_id" in
      deskpi-pro)
        if [[ -c /dev/ttyUSB0 ]]; then
          printf 'power_off' > /dev/ttyUSB0 2>/dev/null || true
        fi
        ;;
      argon-one)
        if command -v i2cset >/dev/null 2>&1 && [[ -c /dev/i2c-1 ]]; then
          i2cset -y 1 0x1a 0x00 2>/dev/null || true
        fi
        ;;
    esac
  '';
in
{
  options.extraLife = {
    case = lib.mkOption {
      type = lib.types.enum [
        "none"
        "retroflag"
        "gpi-case"
        "gpi-case-2"
        "gpi-case-2w"
        "deskpi-pro"
        "argon-one"
      ];
      default = "none";
      description = "Optional retro enclosure profile for safe shutdown, fan control, and display/audio routing.";
    };

    cases = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = deviceCatalogue.cases or { };
      description = "Declarative retro case catalogue parsed from nixos/devices/devices.toml.";
    };
  };

  config = {
    environment.systemPackages = [
      pkgs.i2c-tools
    ];

    systemd.services.extra-life-case = {
      description = "Extra Life retro case fan and power management helper";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${caseHelperScript}";
        ExecStop = "${caseStopScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
