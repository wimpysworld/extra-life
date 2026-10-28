{
  lib,
  stdenv,
  writeShellApplication,
  symlinkJoin,
  coreutils,
  qemu_kvm,
  socat,
  systemd,
  OVMF,
}:
let
  isAarch64 = stdenv.hostPlatform.isAarch64;
  shellApplication = writeShellApplication {
    name = "vm-retro";
    runtimeInputs = [
      coreutils
      qemu_kvm
      socat
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ systemd ];
    runtimeEnv = {
      OVMF_CODE =
        if isAarch64 then "${qemu_kvm}/share/qemu/edk2-aarch64-code.fd" else "${OVMF.fd}/FV/OVMF_CODE.fd";
      OVMF_VARS =
        if isAarch64 then "${qemu_kvm}/share/qemu/edk2-arm-vars.fd" else "${OVMF.fd}/FV/OVMF_VARS.fd";
    };
    text = builtins.readFile ./vm-runner.sh;
  };
in
symlinkJoin {
  name = "vm-retro";
  paths = [ shellApplication ];
  postBuild = ''
    ln -s "$out/bin/vm-retro" "$out/bin/vm-runner"
  '';
  meta = {
    description = "Launch or control the Extra Life QEMU virtual machine";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ flexiondotorg ];
    mainProgram = "vm-retro";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
