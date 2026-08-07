{ self, nixpkgs }:

nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    self.nixosModules.anbernic-rg35xx-h
    self.nixosModules.anbernic-h700-sd-image
    self.nixosModules.anbernic-h700-retroarch

    ({ lib, ... }: {
      networking.hostName = "anbernix-rg35xx-h";
      system.stateVersion = "25.05";

      hardware.anbernic.h700.retroarch = {
        enable = true;
        autostart = true;
      };

      boot = {
        initrd.systemd.enable = false;
        kernelParams = [ "console=tty0" ];

        loader = {
          systemd-boot.enable = false;
          grub.enable = false;
          generic-extlinux-compatible = {
            enable = true;
            configurationLimit = 2;
          };
        };

        zfs.forceImportRoot = false;
      };

      sdImage.compressImage = true;
      fileSystems."/".options = [ "noatime" ];

      documentation.enable = false;
      environment.defaultPackages = lib.mkForce [ ];
      services.fwupd.enable = false;
    })
  ];
}
