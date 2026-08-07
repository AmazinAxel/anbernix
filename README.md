# Anbernix

A NixOS flake providing hardware support for Anbernic Linux handhelds

## Repository Layout

- `modules/`: reusable NixOS hardware modules for downstream configs.
- `pkgs/`: package derivations used by the modules, including the H700 kernel
  and ROCKNIX joypad driver.
- `kernel/`: local kernel config and provenance notes.
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
- `anbernix.nixosModules.anbernic-h700-sd-image`: optional SD image
  post-processing support that injects H700 U-Boot SPL into generated images.

## SD Card Images

The generic NixOS AArch64 SD image module creates partitions and `/boot`
contents, but it does not write the Allwinner H700 SPL/U-Boot blob at the raw
boot offset. Import `anbernic-h700-sd-image` alongside the NixOS SD image module
to produce `system.build.anbernixSdImage`:

```nix
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    anbernix.nixosModules.anbernic-rg35xx-h
    anbernix.nixosModules.anbernic-h700-sd-image
  ];
}
```

Build the flashable image with:

```sh
nix build .#nixosConfigurations.my-handheld.config.system.build.anbernixSdImage
```

The output is a compressed `result/sd-image/*-h700.img.zst` image with the H700
bootloader already written into it. The SD image helper defaults to LPDDR4
U-Boot, which is expected for RG35XX-H units. Boards that need LPDDR3 can set:

```nix
{
  hardware.anbernic.h700.sdImage.ddrType = "lpddr3";
}
```

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
the locked `rocknix` flake input. Patches are read directly from ROCKNIX's H700,
mainline, and kernel-version patch directories. Local kernel deltas are
documented in `kernel/README.md`.

The flake includes eval-only checks for the exported H700, RG35XX-H,
RG35XX-H-with-rumble, and H700 SD image module paths.
