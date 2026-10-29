{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  qmic,
  qrtr,
  systemd,
  udev,
  xz,
}:
let
  qmicLinux = qmic.overrideAttrs (oldAttrs: {
    meta = oldAttrs.meta // {
      platforms = lib.platforms.linux;
    };
  });

  qrtrLinux = qrtr.overrideAttrs (oldAttrs: {
    meta = oldAttrs.meta // {
      platforms = lib.platforms.linux;
    };
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pd-mapper";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "pd-mapper";
    tag = "v${finalAttrs.version}";
    hash = "sha256-I5/N24KONtNRSub00Mqh1GoMHO2qQKTj/ts2N6DQdPc=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    qmicLinux
    qrtrLinux
    systemd
    udev
    xz
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "Qualcomm Protection Domain mapper service";
    homepage = "https://github.com/linux-msm/pd-mapper";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ flexiondotorg ];
    mainProgram = "pd-mapper";
    platforms = lib.platforms.linux;
  };
})
