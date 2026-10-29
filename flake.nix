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
          libretro-cores = applied.libretro-cores or (final.callPackage ./pkgs/libretro-cores { });
          pd-mapper = applied.pd-mapper or (final.callPackage ./pkgs/pd-mapper { });
          ubootAnbernicRgxx3 =
            applied.ubootAnbernicRgxx3 or (final.callPackage ./pkgs/uboot/anbernic-rgxx3.nix { });
          linuxPackages_rpi = applied.linuxPackages_rpi or (final.callPackage ./pkgs/kernels/rpi.nix { });
          linuxPackages_sm6115 =
            applied.linuxPackages_sm6115 or (final.callPackage ./pkgs/kernels/sm6115.nix { });
          vm-retro = applied.vm-retro or (final.callPackage ./pkgs/vm-retro { });
        }
        // applied;

      nixosModules = {
        appliance = import ./nixos/modules/appliance.nix;
        boards = import ./nixos/modules/hardware/boards;
        cases = import ./nixos/modules/hardware/cases;
        disk-base = import ./nixos/modules/images/disk-base.nix;
        disk-efi = import ./nixos/modules/images/disk-efi.nix;
        disk-openabl = import ./nixos/modules/images/disk-openabl.nix;
        disk-rk3566 = import ./nixos/modules/images/disk-rk3566.nix;
        disk-rpi = import ./nixos/modules/images/disk-rpi.nix;
        iso = import ./nixos/modules/images/iso.nix;
        pc = import ./nixos/modules/hardware/pc.nix;
        qemu-guest = import ./nixos/modules/hardware/qemu-guest.nix;
        soc-qcom-common = import ./nixos/modules/hardware/soc/qcom-common.nix;
        soc-rk3566 = import ./nixos/modules/hardware/soc/rk3566.nix;
        soc-rpi-common = import ./nixos/modules/hardware/soc/rpi-common.nix;
        soc-rpi02w = import ./nixos/modules/hardware/soc/rpi02w.nix;
        soc-rpi4 = import ./nixos/modules/hardware/soc/rpi4.nix;
        soc-rpi5 = import ./nixos/modules/hardware/soc/rpi5.nix;
        soc-sm6115 = import ./nixos/modules/hardware/soc/sm6115.nix;
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
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          archPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
        in
        {
          inherit (pkgs) vm-retro;
          iso = self.nixosConfigurations."${archPrefix}-installer".config.system.build.isoImage;
          disk-image = self.nixosConfigurations."${archPrefix}-appliance".config.system.build.diskImage;
          ota-bundle = self.nixosConfigurations."${archPrefix}-appliance".config.system.build.otaBundle;
          default = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ludo else pkgs.vm-retro;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
          disk-image-x86_64 = self.nixosConfigurations.x86_64.config.system.build.diskImage;
          ota-bundle-x86_64 = self.nixosConfigurations.x86_64.config.system.build.otaBundle;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isAarch64 {
          disk-image-aarch64 = self.nixosConfigurations.aarch64.config.system.build.diskImage;
          disk-image-rk3566 = self.nixosConfigurations.rk3566.config.system.build.diskImage;
          disk-image-rpi02w = self.nixosConfigurations.rpi02w.config.system.build.diskImage;
          disk-image-rpi4 = self.nixosConfigurations.rpi4.config.system.build.diskImage;
          disk-image-rpi5 = self.nixosConfigurations.rpi5.config.system.build.diskImage;
          disk-image-sm6115 = self.nixosConfigurations.sm6115.config.system.build.diskImage;
          ota-bundle-aarch64 = self.nixosConfigurations.aarch64.config.system.build.otaBundle;
          ota-bundle-rk3566 = self.nixosConfigurations.rk3566.config.system.build.otaBundle;
          ota-bundle-rpi02w = self.nixosConfigurations.rpi02w.config.system.build.otaBundle;
          ota-bundle-rpi4 = self.nixosConfigurations.rpi4.config.system.build.otaBundle;
          ota-bundle-rpi5 = self.nixosConfigurations.rpi5.config.system.build.otaBundle;
          ota-bundle-sm6115 = self.nixosConfigurations.sm6115.config.system.build.otaBundle;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          inherit (pkgs) ludo libretro-cores pd-mapper;
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          inherit (pkgs) ubootAnbernicRgxx3;
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
              ]
              ++ import ./nix/loader.nix { inherit pkgs; };
            shellHook = import ./nix/hooks.nix { inherit pkgs; };
          };
        }
      );
    };
}
