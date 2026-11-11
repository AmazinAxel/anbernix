{ lib, stdenv, kernel, kernelModuleMakeFlags, rocknix-joypad }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2026-08-30";

  src = rocknix-joypad;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "DEVICE=H700"
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=misc"
    "DEPMOD=true"
  ];

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "ROCKNIX joypad driver";
    license = lib.licenses.gpl2Only;
  };
}
