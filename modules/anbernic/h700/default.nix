{ pkgs, lib, ... }:

let
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${../../../kernel/panels}/*.panel $out/lib/firmware/panels/
  '';
in {
  imports = [
    ../../../kernel/kernel.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "usbhid" "hid" "evdev" "uinput" ];
      allowMissingModules = lib.mkDefault true;
    };
    kernelModules = [ "rocknix-singleadc-joypad" ];
  };

  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    firmware = [ pkgs.linux-firmware anbernicPanelFirmware ];
    uinput.enable = lib.mkDefault true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
