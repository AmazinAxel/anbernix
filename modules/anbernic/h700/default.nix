{ inputs }:
{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.anbernic.h700;
  rocknixFirmware = inputs.rocknix + "/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware";
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-panel.panel $out/lib/firmware/panels/
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-rev6-panel.panel $out/lib/firmware/panels/
  '';
in {
  imports = [
    (import ../../../kernel/kernel.nix {
      inherit inputs;
      enableRumble = cfg.enableRumble;
    })
  ];

  options.hardware.anbernic.h700 = {
    enableRumble = lib.mkEnableOption ''
      experimental rumble support using ROCKNIX's disabled force-feedback patch
    '';
  };

  config = {
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
  };
}
