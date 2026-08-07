{ buildUBoot
, fetchFromGitHub
, armTrustedFirmwareAllwinnerH616
, lib
, rocknix
, ddrType ? "lpddr4"
}:

let
  variants = {
    lpddr3 = "DDR3";
    lpddr4 = "DDR4";
  };
  rocknixVariant = variants.${ddrType} or (throw "Unsupported H700 U-Boot DDR type: ${ddrType}");
  defconfig = "anbernic_rg35xx_h700_${ddrType}_defconfig";
  rocknixUBoot = rocknix + "/projects/ROCKNIX/devices/H700/packages/u-boot-${rocknixVariant}";
in
buildUBoot {
  version = "2026.01";
  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "v2026.01";
    hash = "sha256-ym3yM0InFlmZp0zRlLWBmfCKQHPJNGKqm99bdPWOy5E=";
  };

  inherit defconfig;
  extraPatches = [
    (rocknixUBoot + "/patches/0001-Update-dram_sun50i_h616.c.patch")
  ];

  postPatch = ''
    cp ${rocknixUBoot}/sources/configs/${defconfig} configs/${defconfig}
    patchShebangs tools
    patchShebangs scripts
  '';

  env.BL31 = "${armTrustedFirmwareAllwinnerH616}/bl31.bin";
  filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];

  extraMeta.description = "U-Boot for Allwinner H700 Anbernic handhelds (${lib.toUpper ddrType})";
}
