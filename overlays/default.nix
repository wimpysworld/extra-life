{ inputs, ... }:
let
  overlay = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    cage = prev.cage.overrideAttrs (oldAttrs: {
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

  modifiedPackages = _final: prev: {
    cage = prev.cage.overrideAttrs (oldAttrs: {
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
