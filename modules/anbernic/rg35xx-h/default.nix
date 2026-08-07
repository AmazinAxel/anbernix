{ lib, ... }: {
  imports = [
    ../h700
  ];

  hardware.deviceTree.name = lib.mkDefault "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
}
