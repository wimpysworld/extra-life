{
  lib,
  stdenv,
  fetchFromGitHub,
  libretro,
  runCommand,
  unstable ? null,
}:
let
  chailove = libretro.mkLibretroCore {
    core = "chailove";
    version = "2.0.0-unstable-2023-09-12";
    src = fetchFromGitHub {
      owner = "libretro";
      repo = "chailove";
      rev = "524ef951abbd07464830ee12a3f6f5e2aba9efd3";
      fetchSubmodules = true;
      hash = "sha256-2WwVEMdfEbW7wO86hbG+l/jrbtFhFhfVIHftMnM1XoE=";
    };
    makefile = "Makefile";
    dontConfigure = true;
    meta = {
      description = "2D game framework with ChaiScript for libretro";
      homepage = "https://github.com/libretro/chailove";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ flexiondotorg ];
    };
  };

  pokemini =
    libretro.pokemini or (
      if unstable != null && unstable.libretro ? pokemini then
        unstable.libretro.pokemini
      else
        libretro.mkLibretroCore {
          core = "pokemini";
          version = "0-unstable-2026-07-31";
          src = fetchFromGitHub {
            owner = "libretro";
            repo = "PokeMini";
            rev = "132111b76343559860532a1ccc094f93f1ed5650";
            hash = "sha256-Gyany/aEzDlhLM/zowsOU8LLI4FdWEQ83B+mxHX56UI=";
          };
          makefile = "Makefile";
          meta = {
            description = "Obscure Nintendo handheld emulator";
            homepage = "https://github.com/libretro/PokeMini";
            license = lib.licenses.gpl3Only;
            maintainers = with lib.maintainers; [ flexiondotorg ];
          };
        }
    );

  cores = [
    libretro.atari800
    libretro.beetle-ngp
    libretro.beetle-pce
    libretro.beetle-pcfx
    libretro.beetle-saturn
    libretro.beetle-vb
    libretro.beetle-wswan
    libretro.bluemsx
    chailove
    libretro.citra
    libretro.dolphin
    libretro.fbneo
    libretro.fceumm
    libretro.flycast
    libretro.gambatte
    libretro.genesis-plus-gx
    libretro.handy
    libretro.hatari
    libretro.melonds
    libretro.mgba
    libretro.mupen64plus
    libretro.nxengine
    libretro.o2em
    libretro.picodrive
    pokemini
    libretro.prosystem
    libretro.snes9x
    libretro.stella2014
    libretro.vecx
    libretro.virtualjaguar
  ]
  ++ lib.optional stdenv.hostPlatform.isx86_64 libretro.swanstation
  ++ lib.optional stdenv.hostPlatform.isAarch64 libretro.pcsx-rearmed
  ++ lib.optional stdenv.hostPlatform.isx86_64 libretro.pcsx2
  ++ lib.optional (lib.meta.availableOn stdenv.hostPlatform libretro.ppsspp) libretro.ppsspp;
in
runCommand "libretro-cores"
  {
    passthru = {
      inherit chailove cores pokemini;
    };
    meta = {
      description = "Curated Libretro core farm for Ludo";
      maintainers = with lib.maintainers; [ flexiondotorg ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
  ''
    mkdir -p "$out/lib/retroarch/cores"
    ${lib.concatMapStringsSep "\n" (core: ''
      ln -s "${core}/lib/retroarch/cores/"*.so "$out/lib/retroarch/cores/"
    '') cores}
  ''
