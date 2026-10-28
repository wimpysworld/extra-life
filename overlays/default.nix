{ inputs, ... }:
let
  overlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    connman = prev.connman.override {
      enableOpenconnect = false;
      enableOpenvpn = false;
      enableVpnc = false;
      enablePptp = false;
      enableWireguard = false;
      enableOfono = false;
      enableDundee = false;
      enableNeard = false;
    };

    pipewire =
      (prev.pipewire.override {
        vulkanSupport = false;
        x11Support = false;
        ffadoSupport = false;
        rocSupport = false;
        raopSupport = false;
        zeroconfSupport = false;
      }).overrideAttrs
        (oldAttrs: {
          outputs = [
            "out"
            "jack"
            "dev"
          ];
          buildInputs = builtins.filter (
            p:
            !(builtins.elem (final.lib.getName p) [
              "ffmpeg-headless"
              "gstreamer"
              "gst-plugins-base"
              "libcamera"
              "modemmanager"
            ])
          ) oldAttrs.buildInputs;
          mesonFlags =
            builtins.filter (
              f:
              !(final.lib.hasPrefix "-Ddocs=" f)
              && !(final.lib.hasPrefix "-Dman=" f)
              && !(final.lib.hasPrefix "-Dinstalled_tests=" f)
              && !(final.lib.hasPrefix "-Dinstalled_test_prefix=" f)
              && !(final.lib.hasPrefix "-Dlibcamera=" f)
              && !(final.lib.hasPrefix "-Dgstreamer=" f)
              && !(final.lib.hasPrefix "-Dgstreamer-device-provider=" f)
              && !(final.lib.hasPrefix "-Dffmpeg=" f)
              && !(final.lib.hasPrefix "-Dpw-cat-ffmpeg=" f)
              && !(final.lib.hasPrefix "-Dbluez5-backend-native-mm=" f)
              && !(final.lib.hasPrefix "-Dbluez5-backend-ofono=" f)
            ) oldAttrs.mesonFlags
            ++ [
              (final.lib.mesonEnable "docs" false)
              (final.lib.mesonEnable "man" false)
              (final.lib.mesonEnable "installed_tests" false)
              (final.lib.mesonEnable "libcamera" false)
              (final.lib.mesonEnable "gstreamer" false)
              (final.lib.mesonEnable "gstreamer-device-provider" false)
              (final.lib.mesonEnable "ffmpeg" false)
              (final.lib.mesonEnable "pw-cat-ffmpeg" false)
              (final.lib.mesonEnable "bluez5-backend-native-mm" false)
              (final.lib.mesonEnable "bluez5-backend-ofono" false)
            ];
        });

    wlroots_0_20 =
      (prev.wlroots_0_20.override {
        enableXWayland = false;
      }).overrideAttrs
        (oldAttrs: {
          postFixup = (oldAttrs.postFixup or "") + ''
            rm -rf "$out/nix-support"
          '';
        });

    cage =
      (prev.cage.override {
        inherit (final) wlroots_0_20;
        xwayland = null;
      }).overrideAttrs
        (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            ../patches/cage/teardown-order.patch
          ];
        });

    ludo = final.callPackage ../pkgs/ludo { };

    libretro-cores = final.callPackage ../pkgs/libretro-cores { };
  };
in
{
  __functor = _self: overlay;
  default = overlay;

  unstablePackages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  modifiedPackages = final: prev: {
    connman = prev.connman.override {
      enableOpenconnect = false;
      enableOpenvpn = false;
      enableVpnc = false;
      enablePptp = false;
      enableWireguard = false;
      enableOfono = false;
      enableDundee = false;
      enableNeard = false;
    };

    pipewire =
      (prev.pipewire.override {
        vulkanSupport = false;
        x11Support = false;
        ffadoSupport = false;
        rocSupport = false;
        raopSupport = false;
        zeroconfSupport = false;
      }).overrideAttrs
        (oldAttrs: {
          outputs = [
            "out"
            "jack"
            "dev"
          ];
          buildInputs = builtins.filter (
            p:
            !(builtins.elem (final.lib.getName p) [
              "ffmpeg-headless"
              "gstreamer"
              "gst-plugins-base"
              "libcamera"
              "modemmanager"
            ])
          ) oldAttrs.buildInputs;
          mesonFlags =
            builtins.filter (
              f:
              !(final.lib.hasPrefix "-Ddocs=" f)
              && !(final.lib.hasPrefix "-Dman=" f)
              && !(final.lib.hasPrefix "-Dinstalled_tests=" f)
              && !(final.lib.hasPrefix "-Dinstalled_test_prefix=" f)
              && !(final.lib.hasPrefix "-Dlibcamera=" f)
              && !(final.lib.hasPrefix "-Dgstreamer=" f)
              && !(final.lib.hasPrefix "-Dgstreamer-device-provider=" f)
              && !(final.lib.hasPrefix "-Dffmpeg=" f)
              && !(final.lib.hasPrefix "-Dpw-cat-ffmpeg=" f)
              && !(final.lib.hasPrefix "-Dbluez5-backend-native-mm=" f)
              && !(final.lib.hasPrefix "-Dbluez5-backend-ofono=" f)
            ) oldAttrs.mesonFlags
            ++ [
              (final.lib.mesonEnable "docs" false)
              (final.lib.mesonEnable "man" false)
              (final.lib.mesonEnable "installed_tests" false)
              (final.lib.mesonEnable "libcamera" false)
              (final.lib.mesonEnable "gstreamer" false)
              (final.lib.mesonEnable "gstreamer-device-provider" false)
              (final.lib.mesonEnable "ffmpeg" false)
              (final.lib.mesonEnable "pw-cat-ffmpeg" false)
              (final.lib.mesonEnable "bluez5-backend-native-mm" false)
              (final.lib.mesonEnable "bluez5-backend-ofono" false)
            ];
        });

    wlroots_0_20 =
      (prev.wlroots_0_20.override {
        enableXWayland = false;
      }).overrideAttrs
        (oldAttrs: {
          postFixup = (oldAttrs.postFixup or "") + ''
            rm -rf "$out/nix-support"
          '';
        });

    cage =
      (prev.cage.override {
        inherit (final) wlroots_0_20;
        xwayland = null;
      }).overrideAttrs
        (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            ../patches/cage/teardown-order.patch
          ];
        });
  };

  localPackages = final: _prev: {
    ludo = final.callPackage ../pkgs/ludo { };
    libretro-cores = final.callPackage ../pkgs/libretro-cores { };
  };
}
