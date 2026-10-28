{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  wayland-scanner,
  openal,
  libGL,
  mesa,
  wayland,
  libxkbcommon,
  libX11,
  libXcursor,
  libXrandr,
  libXinerama,
  libXi,
  libXxf86vm,
}:
buildGoModule (_finalAttrs: {
  pname = "ludo";
  version = "0.22.5";

  src = fetchFromGitHub {
    owner = "libretro";
    repo = "ludo";
    rev = "7a2dc452c72e43dc06b5ecc711c3d03c8aeeb261";
    fetchSubmodules = true;
    hash = "sha256-QV1LSYhe7JFKv/AVjFR8Yn1mR87RLuEetb1YeT64GZ8=";
  };

  vendorHash = "sha256-ygteyccbRPHkAaMHw2R9geSQmKBTvOqRxLzVj5wJpmg=";

  subPackages = [ "." ];

  tags = [ "wayland" ];

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    openal
    libGL
    mesa
    wayland
    libxkbcommon
    libX11
    libXcursor
    libXrandr
    libXinerama
    libXi
    libXxf86vm
  ];

  # Upstream tests require an active display server and audio device.
  doCheck = false;

  preBuild = ''
    glfwDir="vendor/github.com/go-gl/glfw/v3.4/glfw/glfw"
    chmod -R u+w "$glfwDir/src"
    for xml in "$glfwDir/deps/wayland/"*.xml; do
      base="$(basename "$xml" .xml)"
      if [ "$base" = "wayland" ]; then
        header="$glfwDir/src/wayland-client-protocol.h"
        code="$glfwDir/src/wayland-client-protocol-code.h"
      else
        header="$glfwDir/src/''${base}-client-protocol.h"
        code="$glfwDir/src/''${base}-client-protocol-code.h"
      fi
      wayland-scanner client-header "$xml" "$header"
      wayland-scanner private-code "$xml" "$code"
    done
  '';

  postInstall = ''
    mkdir -p "$out/share/ludo"
    cp -r assets "$out/share/ludo/assets"
    cp -r database "$out/share/ludo/database"
    rm -f "$out/share/ludo/database/"*.py
  '';

  meta = {
    description = "Minimalist frontend for libretro cores";
    homepage = "https://ludo.libretro.com/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ flexiondotorg ];
    mainProgram = "ludo";
    platforms = lib.platforms.linux;
  };
})
