{
  config,
  lib,
  pkgs,
  ...
}:
let
  deviceCatalogue = builtins.fromTOML (builtins.readFile ../../../devices/devices.toml);
  inherit (config.extraLife) devices;

  defaultBoardId =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      "x86_64-generic"
    else
      "${config.extraLife.variantId}-generic";

  dtModelDevices = lib.filterAttrs (_id: dev: (dev.dt_model or "") != "") devices;
  dtDevices = lib.filterAttrs (_id: dev: (dev.dt_compatibles or [ ]) != [ ]) devices;
  dmiDevices = lib.filterAttrs (
    _id: dev: (dev ? dmi_vendor) && ((dev.dmi_products or [ ]) != [ ])
  ) devices;
  usbFallbackDevices = lib.filterAttrs (_id: dev: (dev.usb_fallbacks or [ ]) != [ ]) devices;

  dtModelBranches = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      id: dev:
      let
        orient = dev.panel_orientation or "normal";
      in
      ''
        ${lib.escapeShellArg dev.dt_model})
          board_id=${lib.escapeShellArg id}
          panel_orientation=${lib.escapeShellArg orient}
          matched=1
          ;;
      ''
    ) dtModelDevices
  );

  dtBranches = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      id: dev:
      let
        boardCompat = builtins.head dev.dt_compatibles;
        orient = dev.panel_orientation or "normal";
      in
      ''
        ${lib.escapeShellArg boardCompat})
          board_id=${lib.escapeShellArg id}
          panel_orientation=${lib.escapeShellArg orient}
          matched=1
          break
          ;;
      ''
    ) dtDevices
  );

  dmiBranches = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      id: dev:
      let
        vendor = lib.escapeShellArg dev.dmi_vendor;
        productsPattern = lib.concatMapStringsSep "|" lib.escapeShellArg dev.dmi_products;
        orient = dev.panel_orientation or "normal";
      in
      ''
        if [[ -z "$matched" ]] && [[ "$sys_vendor" == ${vendor} || "$board_vendor" == ${vendor} ]]; then
          case "$product_name" in
            ${productsPattern})
              board_id=${lib.escapeShellArg id}
              panel_orientation=${lib.escapeShellArg orient}
              matched=1
              ;;
          esac
          if [[ -z "$matched" ]]; then
            case "$board_name" in
              ${productsPattern})
                board_id=${lib.escapeShellArg id}
                panel_orientation=${lib.escapeShellArg orient}
                matched=1
                ;;
            esac
          fi
        fi
      ''
    ) dmiDevices
  );

  usbBranches = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      id: dev:
      let
        usbPattern = lib.concatMapStringsSep "|" (s: lib.escapeShellArg (lib.toLower s)) dev.usb_fallbacks;
        orient = dev.panel_orientation or "normal";
      in
      ''
        ${usbPattern})
          board_id=${lib.escapeShellArg id}
          panel_orientation=${lib.escapeShellArg orient}
          matched=1
          break
          ;;
      ''
    ) usbFallbackDevices
  );

  detectBoardScript = pkgs.writeShellScript "extra-life-detect-board" ''
    set -euo pipefail

    board_id=${lib.escapeShellArg defaultBoardId}
    panel_orientation="normal"
    matched=""

    if [[ -r /proc/device-tree/model ]]; then
      dt_model="$(tr -d '\0' < /proc/device-tree/model)"
      case "$dt_model" in
        ${dtModelBranches}
      esac
    fi

    if [[ -z "$matched" && -r /proc/device-tree/compatible ]]; then
      while IFS= read -r compat; do
        [[ -n "$compat" ]] || continue
        case "$compat" in
          ${dtBranches}
        esac
      done < <(tr '\0' '\n' < /proc/device-tree/compatible)
    fi

    if [[ -z "$matched" && -d /sys/class/dmi/id ]]; then
      sys_vendor=""
      product_name=""
      board_vendor=""
      board_name=""
      [[ -r /sys/class/dmi/id/sys_vendor ]] && IFS= read -r sys_vendor < /sys/class/dmi/id/sys_vendor || true
      [[ -r /sys/class/dmi/id/product_name ]] && IFS= read -r product_name < /sys/class/dmi/id/product_name || true
      [[ -r /sys/class/dmi/id/board_vendor ]] && IFS= read -r board_vendor < /sys/class/dmi/id/board_vendor || true
      [[ -r /sys/class/dmi/id/board_name ]] && IFS= read -r board_name < /sys/class/dmi/id/board_name || true

      ${dmiBranches}

      if [[ -z "$matched" ]] && [[ "$product_name" == "Default string" || "$board_name" == "Default string" || -z "$product_name" ]]; then
        for dev_dir in /sys/bus/usb/devices/*; do
          [[ -r "$dev_dir/idVendor" && -r "$dev_dir/idProduct" ]] || continue
          IFS= read -r vid < "$dev_dir/idVendor" || continue
          IFS= read -r pid < "$dev_dir/idProduct" || continue
          usb_id="''${vid,,}:''${pid,,}"
          case "$usb_id" in
            ${usbBranches}
          esac
        done
      fi
    fi

    cat > /run/extra-life-board.env.tmp <<EOF
    EXTRA_LIFE_BOARD=$board_id
    EXTRA_LIFE_PANEL_ORIENTATION=$panel_orientation
    EOF
    chmod 0644 /run/extra-life-board.env.tmp
    mv -f /run/extra-life-board.env.tmp /run/extra-life-board.env
  '';
in
{
  options.extraLife.devices = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = deviceCatalogue.devices;
    description = "Declarative hardware device catalogue parsed from nixos/devices/devices.toml.";
  };

  config = {
    services.udev = {
      extraRules = ''
        SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="Goodix Capacitive TouchScreen", ATTR{[dmi/id]sys_vendor}=="GPD", ATTR{[dmi/id]product_name}=="WIN2|G1619-01|G1619-02|G1619-03", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 1 0 -1 0 1"
        SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="Goodix Capacitive TouchScreen", ATTR{[dmi/id]sys_vendor}=="Default string", ATTR{[dmi/id]product_name}=="Default string", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 1 0 -1 0 1"
      '';

      extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svnGPD:pnG1619-01:pvr*
         KEYBOARD_KEY_a0=!mute
      '';
    };

    systemd.services.extra-life-board-detect = {
      description = "Detect Extra Life hardware board and display quirks";
      wantedBy = [ "multi-user.target" ];
      before = [ "cage-tty1.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${detectBoardScript}";
      };
    };

    systemd.services."cage-tty1" = {
      after = [ "extra-life-board-detect.service" ];
      wants = [ "extra-life-board-detect.service" ];
      serviceConfig = {
        ExecStartPre = [ "+${detectBoardScript}" ];
        EnvironmentFile = [ "-/run/extra-life-board.env" ];
      };
    };
  };
}
