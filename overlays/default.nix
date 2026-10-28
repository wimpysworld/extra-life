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
