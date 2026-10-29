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
            ../patches/cage/panel-orientation.patch
          ];
        });

    # Determinate Nix 3.23 emits activity type 10113, which nom 2.2.0 rejects
    # with a ParseNixJSONMessageError. Apply the upstream fix that maps
    # unknown activity types to Unknown. Remove this override once a nom
    # release that includes the fix reaches nixpkgs.
    # https://github.com/maralorn/nix-output-monitor/issues/320
    # https://github.com/maralorn/nix-output-monitor/pull/321
    nix-output-monitor = prev.nix-output-monitor.override {
      extraComposeFunctions = [
        (prev.haskell.lib.compose.appendPatch (
          prev.fetchpatch2 {
            url = "https://github.com/maralorn/nix-output-monitor/commit/3c2ae037013e840046ed9785c4da82aa1c628872.patch";
            relative = "nix-output-monitor";
            hash = "sha256-kwmbXQZI+UyOVCAngr6cYpwqIbbG48MJgHzFpCt138o=";
          }
        ))
      ];
    };

    ludo = final.callPackage ../pkgs/ludo { };

    libretro-cores = final.callPackage ../pkgs/libretro-cores { };

    ubootAnbernicRgxx3 = final.callPackage ../pkgs/uboot/anbernic-rgxx3.nix { };
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
            ../patches/cage/panel-orientation.patch
          ];
        });

    # Determinate Nix 3.23 emits activity type 10113, which nom 2.2.0 rejects
    # with a ParseNixJSONMessageError. Apply the upstream fix that maps
    # unknown activity types to Unknown. Remove this override once a nom
    # release that includes the fix reaches nixpkgs.
    # https://github.com/maralorn/nix-output-monitor/issues/320
    # https://github.com/maralorn/nix-output-monitor/pull/321
    nix-output-monitor = prev.nix-output-monitor.override {
      extraComposeFunctions = [
        (prev.haskell.lib.compose.appendPatch (
          prev.fetchpatch2 {
            url = "https://github.com/maralorn/nix-output-monitor/commit/3c2ae037013e840046ed9785c4da82aa1c628872.patch";
            relative = "nix-output-monitor";
            hash = "sha256-kwmbXQZI+UyOVCAngr6cYpwqIbbG48MJgHzFpCt138o=";
          }
        ))
      ];
    };
  };

  localPackages = final: _prev: {
    ludo = final.callPackage ../pkgs/ludo { };
    libretro-cores = final.callPackage ../pkgs/libretro-cores { };
    ubootAnbernicRgxx3 = final.callPackage ../pkgs/uboot/anbernic-rgxx3.nix { };
  };
}
