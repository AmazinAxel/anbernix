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
  };

  outputs = { self, home-manager, nixpkgs, ... }@inputs: {
    nixosModules = {
      anbernic-h700 = ./modules/anbernic/h700;
      anbernic-rg35xx-h = ./modules/anbernic/rg35xx-h;

      h700 = self.nixosModules.anbernic-h700;
      rg35xx-h = self.nixosModules.anbernic-rg35xx-h;
      default = self.nixosModules.anbernic-h700;
    };

    nixosConfigurations."anbernix" = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./anbernix.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
