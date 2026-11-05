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

    inherit
      (
        (import inputs.nixpkgs {
          inherit (final.stdenv.hostPlatform) system;
        })
      )
      retroarch-bare
      ;

    ludo = final.callPackage ../pkgs/ludo { };

    homebrew-roms = final.callPackage ../pkgs/homebrew-roms { };

    libretro-cores = final.callPackage ../pkgs/libretro-cores { };

    pd-mapper = final.callPackage ../pkgs/pd-mapper { };

    ubootAnbernicH700 = final.callPackage ../pkgs/uboot/anbernic-h700.nix { };

    ubootAnbernicRgxx3 = final.callPackage ../pkgs/uboot/anbernic-rgxx3.nix { };

    ubootPowkiddyX55 = final.callPackage ../pkgs/uboot/powkiddy-x55.nix { };

    ubootRk3326 = final.callPackage ../pkgs/uboot/rk3326.nix { };

    ubootRk3588 = final.callPackage ../pkgs/uboot/rk3588.nix { };

    rocknix-h700 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/H700"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/H700"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
      ];
      hash = "sha256-+W507E7TEarFyQqhkpu+hrYhrI/7HKXZG06YuwxajRo=";
    };

    rocknix-joypad = final.fetchFromGitHub {
      owner = "hackbar";
      repo = "rocknix-joypad";
      rev = "005033d1ddd8746c771f2c81f1174f2d892541c9";
      hash = "sha256-uprZYBDSjmSP0+MRK4e0mkRrij84zYg6eb5wtAtYsLo=";
    };

    rocknix-rk3326 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3326"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux/patches/mainline-rockchip"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326"
      ];
      hash = "sha256-UYFpR602bB+sVNt00XDXr5ZhaSlmjCQkixtuZiwznu0=";
    };

    rocknix-rk3566 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3566"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
      ];
      hash = "sha256-Aq33TGwj/lwtztrgXAIEmynRQwSJAymM1es0GBWyceU=";
    };

    rocknix-rk3588 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3588"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-EkE55LsnGQifC2j1s9wdejuqKHg2kUyT8gwe+GB9RgM=";
    };

    rocknix-sm6115 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM6115"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-4xnHG+Ix8s/nPWeoqKhy52G8+3hIVGHXUfxMntcZOYw=";
    };

    rocknix-sm8250 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM8250"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8250"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-9Ox2liSB8UQFDCjCJoP0Ps1TxtByiId72n/etYDycHY=";
    };

    rocknix-sm8550 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM8550"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8550"
      ];
      hash = "sha256-5Sb2DjyPyVSjR8iaUlUQBL+Lj8WhYnlq+aWpK2XpOHY=";
    };

    linuxPackages_h700 = final.callPackage ../pkgs/kernels/h700.nix { };

    linuxPackages_rk3326 = final.callPackage ../pkgs/kernels/rk3326.nix { };

    linuxPackages_rk3566 = final.callPackage ../pkgs/kernels/rk3566.nix { };

    linuxPackages_rk3588 = final.callPackage ../pkgs/kernels/rk3588.nix { };

    linuxPackages_rpi = final.callPackage ../pkgs/kernels/rpi.nix { };

    linuxPackages_sm6115 = final.callPackage ../pkgs/kernels/sm6115.nix { };

    linuxPackages_sm8250 = final.callPackage ../pkgs/kernels/sm8250.nix { };

    linuxPackages_sm8550 = final.callPackage ../pkgs/kernels/sm8550.nix { };
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

    inherit
      (
        (import inputs.nixpkgs {
          inherit (final.stdenv.hostPlatform) system;
        })
      )
      retroarch-bare
      ;
  };

  localPackages = final: _prev: {
    ludo = final.callPackage ../pkgs/ludo { };
    homebrew-roms = final.callPackage ../pkgs/homebrew-roms { };
    libretro-cores = final.callPackage ../pkgs/libretro-cores { };
    pd-mapper = final.callPackage ../pkgs/pd-mapper { };
    ubootAnbernicH700 = final.callPackage ../pkgs/uboot/anbernic-h700.nix { };
    ubootAnbernicRgxx3 = final.callPackage ../pkgs/uboot/anbernic-rgxx3.nix { };
    ubootPowkiddyX55 = final.callPackage ../pkgs/uboot/powkiddy-x55.nix { };
    ubootRk3326 = final.callPackage ../pkgs/uboot/rk3326.nix { };
    ubootRk3588 = final.callPackage ../pkgs/uboot/rk3588.nix { };
    rocknix-h700 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/H700"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/H700"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
      ];
      hash = "sha256-+W507E7TEarFyQqhkpu+hrYhrI/7HKXZG06YuwxajRo=";
    };
    rocknix-joypad = final.fetchFromGitHub {
      owner = "hackbar";
      repo = "rocknix-joypad";
      rev = "005033d1ddd8746c771f2c81f1174f2d892541c9";
      hash = "sha256-uprZYBDSjmSP0+MRK4e0mkRrij84zYg6eb5wtAtYsLo=";
    };
    rocknix-rk3326 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3326"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux/patches/mainline-rockchip"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/RK3326"
      ];
      hash = "sha256-UYFpR602bB+sVNt00XDXr5ZhaSlmjCQkixtuZiwznu0=";
    };
    rocknix-rk3566 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3566"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware/panels"
      ];
      hash = "sha256-Aq33TGwj/lwtztrgXAIEmynRQwSJAymM1es0GBWyceU=";
    };
    rocknix-rk3588 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/RK3588"
        "projects/ROCKNIX/packages/linux/patches/mainline"
        "projects/ROCKNIX/packages/linux-drivers/generic-dsi"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-EkE55LsnGQifC2j1s9wdejuqKHg2kUyT8gwe+GB9RgM=";
    };
    rocknix-sm6115 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM6115"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-4xnHG+Ix8s/nPWeoqKhy52G8+3hIVGHXUfxMntcZOYw=";
    };
    rocknix-sm8250 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM8250"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8250"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/sources/ucm2"
      ];
      hash = "sha256-9Ox2liSB8UQFDCjCJoP0Ps1TxtByiId72n/etYDycHY=";
    };
    rocknix-sm8550 = final.fetchFromGitHub {
      owner = "ROCKNIX";
      repo = "distribution";
      rev = "2a01f59e3329fd14923ccbe6f703cd84f0367196";
      sparseCheckout = [
        "projects/ROCKNIX/devices/SM8550"
        "projects/ROCKNIX/packages/linux/patches/7.2"
        "projects/ROCKNIX/packages/audio/alsa-ucm-conf/patches/SM8550"
      ];
      hash = "sha256-5Sb2DjyPyVSjR8iaUlUQBL+Lj8WhYnlq+aWpK2XpOHY=";
    };
    linuxPackages_h700 = final.callPackage ../pkgs/kernels/h700.nix { };
    linuxPackages_rk3326 = final.callPackage ../pkgs/kernels/rk3326.nix { };
    linuxPackages_rk3566 = final.callPackage ../pkgs/kernels/rk3566.nix { };
    linuxPackages_rk3588 = final.callPackage ../pkgs/kernels/rk3588.nix { };
    linuxPackages_rpi = final.callPackage ../pkgs/kernels/rpi.nix { };
    linuxPackages_sm6115 = final.callPackage ../pkgs/kernels/sm6115.nix { };
    linuxPackages_sm8250 = final.callPackage ../pkgs/kernels/sm8250.nix { };
    linuxPackages_sm8550 = final.callPackage ../pkgs/kernels/sm8550.nix { };
  };
}
