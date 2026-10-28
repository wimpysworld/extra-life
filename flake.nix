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
          vm-retro = applied.vm-retro or (final.callPackage ./pkgs/vm-retro { });
        }
        // applied;

      nixosModules = {
        appliance = import ./nixos/modules/appliance.nix;
        disk-efi = import ./nixos/modules/images/disk-efi.nix;
        iso = import ./nixos/modules/images/iso.nix;
        pc = import ./nixos/modules/hardware/pc.nix;
        qemu-guest = import ./nixos/modules/hardware/qemu-guest.nix;
        default = self.nixosModules.appliance;
      };

      nixosConfigurations = {
        x86_64-appliance = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/x86_64-appliance
          ];
        };

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

        aarch64-installer = lib.nixosSystem {
          modules = [
            nixpkgsModule
            ./nixos/hosts/aarch64-installer
          ];
        };
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
          default = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ludo else pkgs.vm-retro;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          inherit (pkgs) ludo libretro-cores;
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
            packages = with pkgs; [
              deadnix
              findutils
              git
              jq
              just
              mcp-nixos
              nix-output-monitor
              nixfmt
              nixfmt-tree
              statix
              vm-retro
            ];
          };
        }
      );
    };
}
