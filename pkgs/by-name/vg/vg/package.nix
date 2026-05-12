{
  lib,
  stdenv,
  fetchFromGitHub,

  pkg-config,

  sdsl-lite,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vg";
  version = "1.74.0";

  src = fetchFromGitHub {
    owner = "vgteam";
    repo = "vg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-22Q7CZ4GncCaiuJHZk9vUlVf+0Q4Mrf+esD70OLNk3I=";
    fetchSubmodules = true;
  };

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail "/bin/bash" "${stdenv.shell}"

    patchShebangs scripts/
  '';

  preBuild = ''
    mkdir -p lib
    cp ${sdsl-lite}/lib/libsdsl.a lib/
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  meta = {
    description = "Tools for working with genome variation graphs";
    homepage = "https://github.com/vgteam/vg";
    mainProgram = "vg";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
