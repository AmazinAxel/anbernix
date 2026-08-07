# Anbernix

A NixOS flake providing hardware support for Anbernic Linux handhelds

## NixOS Modules

To use, import and apply the module for your device, like so:

```nix
{
  inputs.anbernix.url = "github:OWNER/anbernix";

  outputs = { nixpkgs, anbernix, ... }: {
    nixosConfigurations.my-handheld = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        anbernix.nixosModules.anbernic-rg35xx-h
        ./configuration.nix
      ];
    };
  };
}
```

Available modules:

- `anbernix.nixosModules.anbernic-h700`: shared Allwinner H700 support.
- `anbernix.nixosModules.anbernic-rg35xx-h`: RG35XX-H support, including the
  H700 module and the RG35XX-H device tree name.

The kernel patch set is based on ROCKNIX's H700 support from
the locked `rocknix` flake input. Most patches are read directly from
`ROCKNIX/distribution/projects/ROCKNIX/devices/H700`, plus selected ROCKNIX
mainline support patches used by the out-of-tree joypad driver. Local kernel
deltas are documented in `kernel/README.md`.
