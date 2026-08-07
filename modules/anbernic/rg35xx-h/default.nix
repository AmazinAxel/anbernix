{ inputs }:
{ lib, ... }: {
  imports = [
    (import ../h700 { inherit inputs; })
  ];

  hardware.deviceTree.name = lib.mkDefault "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
}
