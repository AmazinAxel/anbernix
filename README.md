# Anbernix

A NixOS flake providing hardware support for Anbernic Linux handhelds

## Repository Layout

- `modules/`: reusable NixOS hardware modules for downstream configs.
- `pkgs/`: package derivations used by the modules, including the H700 kernel
  and ROCKNIX joypad driver.
- `kernel/`: local kernel config, provenance notes, and local-only kernel
  patches.
- `profiles/`: optional system/user profiles for this repository's own image.
- `hosts/`: complete host configurations maintained in this repository.

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

### Rumble Support

Rumble is disabled by default. ROCKNIX currently ships its H700 force-feedback
patch as `0150-add-forcefeedback.patch.disabled` because the current H700 PWM
driver is not considered reliable enough upstream.

You can opt in for testing:

```nix
{
  hardware.anbernic.h700.enableRumble = true;
}
```

The kernel patch set is based on ROCKNIX's H700 support from
the locked `rocknix` flake input. Most patches are read directly from
`ROCKNIX/distribution/projects/ROCKNIX/devices/H700`, plus selected ROCKNIX
mainline support patches used by the out-of-tree joypad driver. Local kernel
deltas are documented in `kernel/README.md`.

The flake includes eval-only checks for the exported H700, RG35XX-H, and
RG35XX-H-with-rumble module paths.
