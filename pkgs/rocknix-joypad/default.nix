{ lib, stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2026-08-14";

  src = fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "rocknix-joypad";
    rev = "1dd1115c8d231ba934253efb91ffb0c6ad8e993d";
    hash = "sha256-CPuvujQhfnrfYO6GnlrwbEeTpzTciKaoDfoOn3V+BrE=";
  };

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
