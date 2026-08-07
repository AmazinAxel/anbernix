{ lib, stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2026-08-01";

  src = fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "rocknix-joypad";
    rev = "a6b24835aa1e6339360d08baacd401bb09d08049";
    hash = "sha256-ZZ63fN2rAbSbQp11ealvUd74rsdUHD5mcIDYmje1vwg=";
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
