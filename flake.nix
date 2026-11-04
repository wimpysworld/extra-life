{
  description = "Extra Life - NixOS retro game appliance running Ludo on Cage";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = lib.genAttrs supportedSystems;

      rawOverlay = import ./overlays/default.nix;

      overlayFromFile =
        if builtins.isFunction rawOverlay then
          let
            fnArgs = builtins.functionArgs rawOverlay;
          in
          if fnArgs == { } then
            rawOverlay
          else
            let
              res = rawOverlay {
                inherit
                  inputs
                  self
                  nixpkgs
                  nixpkgs-unstable
                  ;
              };
            in
            if builtins.isFunction res then
              res
            else
              res.default or (final: prev: lib.composeManyExtensions (builtins.attrValues res) final prev)
        else if builtins.isAttrs rawOverlay && rawOverlay ? default then
          rawOverlay.default
        else
          rawOverlay;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        };

      nixpkgsModule = {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default =
        final: prev:
        let
          prevWithUnstable = prev // {
            unstable =
              prev.unstable or (import nixpkgs-unstable {
                inherit (final.stdenv.hostPlatform) system;
                config.allowUnfree = true;
              });
          };
          applied = overlayFromFile final prevWithUnstable;
        in
        {
          inherit (prevWithUnstable) unstable;
          ludo = applied.ludo or (final.callPackage ./pkgs/ludo { });
          homebrew-roms = applied.homebrew-roms or (final.callPackage ./pkgs/homebrew-roms { });
          libretro-cores = applied.libretro-cores or (final.callPackage ./pkgs/libretro-cores { });
          pd-mapper = applied.pd-mapper or (final.callPackage ./pkgs/pd-mapper { });
          ubootAnbernicH700 =
            applied.ubootAnbernicH700 or (final.callPackage ./pkgs/uboot/anbernic-h700.nix { });
          ubootAnbernicRgxx3 =
            applied.ubootAnbernicRgxx3 or (final.callPackage ./pkgs/uboot/anbernic-rgxx3.nix { });
          ubootPowkiddyX55 =
            applied.ubootPowkiddyX55 or (final.callPackage ./pkgs/uboot/powkiddy-x55.nix { });
          linuxPackages_h700 = applied.linuxPackages_h700 or (final.callPackage ./pkgs/kernels/h700.nix { });
          linuxPackages_rk3566 =
            applied.linuxPackages_rk3566 or (final.callPackage ./pkgs/kernels/rk3566.nix { });
          linuxPackages_rpi = applied.linuxPackages_rpi or (final.callPackage ./pkgs/kernels/rpi.nix { });
          linuxPackages_sm6115 =
            applied.linuxPackages_sm6115 or (final.callPackage ./pkgs/kernels/sm6115.nix { });
          linuxPackages_sm8250 =
            applied.linuxPackages_sm8250 or (final.callPackage ./pkgs/kernels/sm8250.nix { });
          linuxPackages_sm8550 =
            applied.linuxPackages_sm8550 or (final.callPackage ./pkgs/kernels/sm8550.nix { });
          vm-retro = applied.vm-retro or (final.callPackage ./pkgs/vm-retro { });
        }
        // applied;

      nixosModules = {
        appliance = import ./nixos/modules/appliance.nix;
        boards = import ./nixos/modules/hardware/boards;
        cases = import ./nixos/modules/hardware/cases;
        disk-base = import ./nixos/modules/images/disk-base.nix;
        disk-efi = import ./nixos/modules/images/disk-efi.nix;
        disk-h700 = import ./nixos/modules/images/disk-h700.nix;
        disk-openabl = import ./nixos/modules/images/disk-openabl.nix;
        disk-rk3566 = import ./nixos/modules/images/disk-rk3566.nix;
        disk-rpi = import ./nixos/modules/images/disk-rpi.nix;
        iso = import ./nixos/modules/images/iso.nix;
        pc = import ./nixos/modules/hardware/pc.nix;
        qemu-guest = import ./nixos/modules/hardware/qemu-guest.nix;
        soc-h700 = import ./nixos/modules/hardware/soc/h700.nix;
        soc-qcom-common = import ./nixos/modules/hardware/soc/qcom-common.nix;
        soc-rk3566 = import ./nixos/modules/hardware/soc/rk3566.nix;
        soc-rpi-common = import ./nixos/modules/hardware/soc/rpi-common.nix;
        soc-rpi02w = import ./nixos/modules/hardware/soc/rpi02w.nix;
        soc-rpi4 = import ./nixos/modules/hardware/soc/rpi4.nix;
        soc-rpi5 = import ./nixos/modules/hardware/soc/rpi5.nix;
        soc-sm6115 = import ./nixos/modules/hardware/soc/sm6115.nix;
        soc-sm8250 = import ./nixos/modules/hardware/soc/sm8250.nix;
        soc-sm8550 = import ./nixos/modules/hardware/soc/sm8550.nix;
        soc-x86_64 = import ./nixos/modules/hardware/soc/x86_64.nix;
        default = self.nixosModules.appliance;
      };

      nixosConfigurations = {
        x86_64-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/x86_64-appliance
          ];
        };

        x86_64 = self.nixosConfigurations.x86_64-appliance;

        x86_64-installer = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/x86_64-installer
          ];
        };

        aarch64-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/aarch64-appliance
          ];
        };

        aarch64 = self.nixosConfigurations.aarch64-appliance;

        aarch64-installer = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/aarch64-installer
          ];
        };

        h700-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/h700-appliance
          ];
        };

        h700 = self.nixosConfigurations.h700-appliance;

        rk3566-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/rk3566-appliance
          ];
        };

        rk3566 = self.nixosConfigurations.rk3566-appliance;

        rpi02w-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/rpi02w-appliance
          ];
        };

        rpi02w = self.nixosConfigurations.rpi02w-appliance;

        rpi4-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/rpi4-appliance
          ];
        };

        rpi4 = self.nixosConfigurations.rpi4-appliance;

        rpi5-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/rpi5-appliance
          ];
        };

        rpi5 = self.nixosConfigurations.rpi5-appliance;

        sm6115-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/sm6115-appliance
          ];
        };

        sm6115 = self.nixosConfigurations.sm6115-appliance;

        sm8250-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/sm8250-appliance
          ];
        };

        sm8250 = self.nixosConfigurations.sm8250-appliance;

        sm8550-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/sm8550-appliance
          ];
        };

        sm8550 = self.nixosConfigurations.sm8550-appliance;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          archPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
          crossAarch64 = pkgs.pkgsCross.aarch64-multiplatform;
          aarch64HostConfig =
            name:
            let
              base = self.nixosConfigurations.${name};
            in
            if system == "x86_64-linux" then
              base.extendModules {
                modules = [
                  {
                    extraLife.buildHostPkgs = pkgs;
                    nixpkgs.overlays = [
                      (_final: _prev: {
                        inherit (crossAarch64)
                          ubootAnbernicH700
                          ubootAnbernicRgxx3
                          ubootPowkiddyX55
                          linuxPackages_h700
                          linuxPackages_rk3566
                          linuxPackages_rpi
                          linuxPackages_sm6115
                          linuxPackages_sm8250
                          linuxPackages_sm8550
                          ;
                      })
                    ];
                  }
                ];
              }
            else
              base;
        in
        {
          inherit (pkgs) homebrew-roms vm-retro;
          iso = self.nixosConfigurations."${archPrefix}-installer".config.system.build.isoImage;
          disk-image = self.nixosConfigurations."${archPrefix}-appliance".config.system.build.diskImage;
          ota-bundle = self.nixosConfigurations."${archPrefix}-appliance".config.system.build.otaBundle;
          default = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ludo else pkgs.vm-retro;
          disk-image-x86_64 = self.nixosConfigurations.x86_64.config.system.build.diskImage;
          ota-bundle-x86_64 = self.nixosConfigurations.x86_64.config.system.build.otaBundle;
          disk-image-aarch64 = (aarch64HostConfig "aarch64").config.system.build.diskImage;
          disk-image-h700 = (aarch64HostConfig "h700").config.system.build.diskImage;
          disk-image-anbernic-rg35xx-plus =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg35xxPlus;
          disk-image-anbernic-rg35xx-2024 =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg35xx2024;
          disk-image-anbernic-rg35xx-pro =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg35xxPro;
          disk-image-anbernic-rg35xx-h =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg35xxH;
          disk-image-anbernic-rg35xx-sp =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg35xxSp;
          disk-image-anbernic-rg40xx-h =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg40xxH;
          disk-image-anbernic-rg40xx-v =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg40xxV;
          disk-image-anbernic-rg-cubexx =
            (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRgCubexx;
          disk-image-anbernic-rg28xx = (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg28xx;
          disk-image-anbernic-rg34xx = (aarch64HostConfig "h700").config.system.build.diskImageAnbernicRg34xx;
          disk-image-rk3566 = (aarch64HostConfig "rk3566").config.system.build.diskImage;
          disk-image-powkiddy-rgb20sx =
            (aarch64HostConfig "rk3566").config.system.build.diskImagePowkiddyRgb20sx;
          disk-image-powkiddy-x35s = (aarch64HostConfig "rk3566").config.system.build.diskImagePowkiddyX35s;
          disk-image-powkiddy-x55 = (aarch64HostConfig "rk3566").config.system.build.diskImagePowkiddyX55;
          disk-image-rpi02w = (aarch64HostConfig "rpi02w").config.system.build.diskImage;
          disk-image-rpi4 = (aarch64HostConfig "rpi4").config.system.build.diskImage;
          disk-image-rpi5 = (aarch64HostConfig "rpi5").config.system.build.diskImage;
          disk-image-sm6115 = (aarch64HostConfig "sm6115").config.system.build.diskImage;
          disk-image-sm8250 = (aarch64HostConfig "sm8250").config.system.build.diskImage;
          disk-image-sm8550 = (aarch64HostConfig "sm8550").config.system.build.diskImage;
          ota-bundle-aarch64 = (aarch64HostConfig "aarch64").config.system.build.otaBundle;
          ota-bundle-h700 = (aarch64HostConfig "h700").config.system.build.otaBundle;
          ota-h700 = self.packages.${system}.ota-bundle-h700;
          ota-bundle-rk3566 = (aarch64HostConfig "rk3566").config.system.build.otaBundle;
          ota-bundle-rpi02w = (aarch64HostConfig "rpi02w").config.system.build.otaBundle;
          ota-bundle-rpi4 = (aarch64HostConfig "rpi4").config.system.build.otaBundle;
          ota-bundle-rpi5 = (aarch64HostConfig "rpi5").config.system.build.otaBundle;
          ota-bundle-sm6115 = (aarch64HostConfig "sm6115").config.system.build.otaBundle;
          ota-bundle-sm8250 = (aarch64HostConfig "sm8250").config.system.build.otaBundle;
          ota-sm8250 = self.packages.${system}.ota-bundle-sm8250;
          ota-bundle-sm8550 = (aarch64HostConfig "sm8550").config.system.build.otaBundle;
          ota-sm8550 = self.packages.${system}.ota-bundle-sm8550;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          inherit (pkgs) ludo libretro-cores pd-mapper;
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          inherit (pkgs) ubootAnbernicH700 ubootAnbernicRgxx3 ubootPowkiddyX55;
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          inherit (crossAarch64) ubootAnbernicH700 ubootAnbernicRgxx3 ubootPowkiddyX55;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          vm-retro = {
            type = "app";
            program = "${pkgs.vm-retro}/bin/vm-retro";
          };
          default = self.apps.${system}.vm-retro;
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.nixfmt-tree
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                actionlint
                deadnix
                findutils
                git
                jq
                just
                mcp-nixos
                nix-output-monitor
                nixfmt
                nixfmt-tree
                rclone
                sops
                statix
                vm-retro
                wrangler
                xz
                zstd
              ]
              ++ import ./nix/loader.nix { inherit pkgs; };
            shellHook = import ./nix/hooks.nix { inherit pkgs; };
          };
        }
      );
    };
}
