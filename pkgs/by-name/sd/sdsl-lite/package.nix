{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sdsl-lite";
  version = "2.3.1-vgteam-unstable-2025-10-28";

  src = fetchFromGitHub {
    owner = "vgteam";
    repo = "sdsl-lite";
    rev = "349de444ded81547cb55a718abeada41960531b5";
    hash = "sha256-/KWOpoGqKNgmjw3Qbfee0WoYqaPgjH44WorgR1cfeHg=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
  ];

  postFixup = ''
    mkdir -p $out/opt
    cp -R . $out/opt
  '';

  env.CMAKE_POLICY_VERSION_MINIMUM = "3.5";

  meta = {
    description = "Succinct Data Structure Library 2.0";
    homepage = "https://github.com/vgteam/sdsl-lite";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
