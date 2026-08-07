{ inputs }:
{ pkgs, lib, ... }:

let
  rocknixFirmware = inputs.rocknix + "/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware";
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-panel.panel $out/lib/firmware/panels/
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-rev6-panel.panel $out/lib/firmware/panels/
  '';
in {
  imports = [
    (import ../../../kernel/kernel.nix { inherit inputs; })
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
