{ inputs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.anbernic.h700.sdImage;

  uBootH700 = pkgs.callPackage ../../../pkgs/u-boot-h700 {
    rocknix = inputs.rocknix;
    ddrType = cfg.ddrType;
  };

  patchedImageName = "${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}-h700.img.zst";
in {
  options.hardware.anbernic.h700.sdImage.ddrType = lib.mkOption {
    type = lib.types.enum [ "lpddr3" "lpddr4" ];
    default = "lpddr4";
    description = ''
      H700 DRAM type to use for the U-Boot SPL written into generated SD images.
      ROCKNIX ships LPDDR3 and LPDDR4 variants; RG35XX-H units are expected to
      use LPDDR4, but this can be set to LPDDR3 for boards that need it.
    '';
  };

  config = {
    assertions = [
      {
        assertion = lib.hasAttrByPath [ "system" "build" "sdImage" ] config;
        message = ''
          anbernic-h700-sd-image must be used with a NixOS SD image module,
          such as nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix.
        '';
      }
      {
        assertion = lib.attrByPath [ "sdImage" "compressImage" ] true config;
        message = ''
          anbernic-h700-sd-image expects a compressed .img.zst SD image. Set
          sdImage.compressImage = true.
        '';
      }
    ];

    system.build.anbernixSdImage = pkgs.runCommand "anbernix-h700-sd-image" {
      nativeBuildInputs = [ pkgs.zstd ];
    } ''
      mkdir -p $out/sd-image

      zstd -dc ${config.system.build.sdImage}/sd-image/*.img.zst > image.img
      dd if=${uBootH700}/u-boot-sunxi-with-spl.bin of=image.img bs=1K seek=8 conv=notrunc
      zstd -T0 -19 image.img -o $out/sd-image/${patchedImageName}
    '';
  };
}
