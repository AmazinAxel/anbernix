{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rocknix = {
      url = "github:ROCKNIX/distribution/next";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    packages.aarch64-linux =
      let
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        linux-h700 = pkgs.callPackage ./pkgs/linux-h700 {
          rocknix = inputs.rocknix;
        };
        linuxPackages-h700 = pkgs.linuxPackagesFor linux-h700;
      in {
        inherit linux-h700;
        rocknix-joypad = linuxPackages-h700.callPackage ./pkgs/rocknix-joypad { };
        u-boot-h700 = pkgs.callPackage ./pkgs/u-boot-h700 {
          rocknix = inputs.rocknix;
        };
        u-boot-h700-lpddr3 = pkgs.callPackage ./pkgs/u-boot-h700 {
          rocknix = inputs.rocknix;
          ddrType = "lpddr3";
        };
        u-boot-h700-lpddr4 = pkgs.callPackage ./pkgs/u-boot-h700 {
          rocknix = inputs.rocknix;
          ddrType = "lpddr4";
        };
        retroarch-h700 = pkgs.callPackage ./pkgs/retroarch-h700 { };
        rg35xx-h-sd-image = self.nixosConfigurations.rg35xx-h.config.system.build.anbernixSdImage;
        default = self.packages.aarch64-linux.rg35xx-h-sd-image;
      };

    nixosModules = {
      anbernic-h700 = import ./modules/anbernic/h700 { inherit inputs; };
      anbernic-h700-sd-image = import ./modules/anbernic/h700-sd-image { inherit inputs; };
      anbernic-h700-retroarch = import ./modules/anbernic/h700-retroarch { inherit self; };
      anbernic-rg35xx-h = import ./modules/anbernic/rg35xx-h { inherit inputs; };

      h700 = self.nixosModules.anbernic-h700;
      h700-sd-image = self.nixosModules.anbernic-h700-sd-image;
      h700-retroarch = self.nixosModules.anbernic-h700-retroarch;
      rg35xx-h = self.nixosModules.anbernic-rg35xx-h;
      default = self.nixosModules.anbernic-h700;
    };

    checks.aarch64-linux =
      let
        minimalSystem = modules:
          (nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = modules ++ [
              {
                boot.loader.grub.enable = false;
                boot.supportedFilesystems.zfs = nixpkgs.lib.mkForce false;
                boot.zfs.forceImportRoot = false;
                fileSystems."/" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                system.stateVersion = "26.11";
              }
            ];
          }).config.system.build.toplevel;
      in {
        anbernic-h700-module = minimalSystem [
          self.nixosModules.anbernic-h700
        ];
        anbernic-rg35xx-h-module = minimalSystem [
          self.nixosModules.anbernic-rg35xx-h
        ];
        anbernic-h700-sd-image-module =
          (nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              self.nixosModules.anbernic-rg35xx-h
              self.nixosModules.anbernic-h700-sd-image
              {
                boot.loader.grub.enable = false;
                boot.supportedFilesystems.zfs = nixpkgs.lib.mkForce false;
                boot.zfs.forceImportRoot = false;
                system.stateVersion = "26.11";
              }
            ];
          }).config.system.build.anbernixSdImage;
        anbernic-h700-retroarch-module = minimalSystem [
          self.nixosModules.anbernic-rg35xx-h
          self.nixosModules.anbernic-h700-retroarch
          { hardware.anbernic.h700.retroarch.enable = true; }
        ];
      };

    nixosConfigurations = {
      rg35xx-h = import ./hosts/rg35xx-h {
        inherit self nixpkgs;
      };
    };
  };
}
