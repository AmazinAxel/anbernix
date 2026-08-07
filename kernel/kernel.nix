{ inputs, enableRumble ? false }:
{ pkgs, ... }:

let
  h700Kernel = pkgs.callPackage ../pkgs/linux-h700 {
    rocknix = inputs.rocknix;
    inherit enableRumble;
  };
  h700LinuxPackages = pkgs.linuxPackagesFor h700Kernel;
  rocknixJoypad = h700LinuxPackages.callPackage ../pkgs/rocknix-joypad { };
in {
  boot.kernelPackages = h700LinuxPackages;
  boot.extraModulePackages = [ rocknixJoypad ];
}
