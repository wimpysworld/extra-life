{
  lib,
  writeShellApplication,
  symlinkJoin,
  coreutils,
  qemu_kvm,
  socat,
  systemd,
  OVMF,
}:
let
  shellApplication = writeShellApplication {
    name = "vm-retro";
    runtimeInputs = [
      coreutils
      qemu_kvm
      socat
      systemd
    ];
    runtimeEnv = {
      OVMF_CODE = "${OVMF.fd}/FV/OVMF_CODE.fd";
      OVMF_VARS = "${OVMF.fd}/FV/OVMF_VARS.fd";
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
    platforms = [ "x86_64-linux" ];
  };
}
