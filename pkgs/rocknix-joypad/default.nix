{ lib, stdenv, kernel, rocknix-joypad }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2026-08-14";

  src = rocknix-joypad;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make DEVICE=H700 -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/misc
    cp *.ko $out/lib/modules/${kernel.modDirVersion}/misc/
    runHook postInstall
  '';

  meta = {
    description = "ROCKNIX joypad driver";
    license = lib.licenses.gpl2Only;
  };
}
