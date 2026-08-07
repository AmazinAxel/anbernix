{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    rocknix = {
      url = "github:ROCKNIX/distribution/next";
      flake = false;
    };
  };

  outputs = { self, home-manager, nixpkgs, ... }@inputs: {
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
      };

    nixosModules = {
      anbernic-h700 = import ./modules/anbernic/h700 { inherit inputs; };
      anbernic-rg35xx-h = import ./modules/anbernic/rg35xx-h { inherit inputs; };

      h700 = self.nixosModules.anbernic-h700;
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
                fileSystems."/" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                system.stateVersion = "25.05";
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
        anbernic-rg35xx-h-rumble-module = minimalSystem [
          self.nixosModules.anbernic-rg35xx-h
          { hardware.anbernic.h700.enableRumble = true; }
        ];
      };

    nixosConfigurations."anbernix" = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/alechandheld/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
