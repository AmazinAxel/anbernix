{ lib, stdenv, kernel, rocknix-joypad }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2026-08-30";

  src = rocknix-joypad;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make DEVICE=H700 -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make DEVICE=H700 -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD \
      INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=misc DEPMOD=true modules_install
    runHook postInstall
  '';

  meta = {
    description = "ROCKNIX joypad driver";
    license = lib.licenses.gpl2Only;
  };
}
