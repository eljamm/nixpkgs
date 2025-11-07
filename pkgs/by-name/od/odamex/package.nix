{
  lib,
  stdenv,
  fetchFromGitHub,

  cmake,
  deutex,
  makeWrapper,
  pkg-config,

  SDL2,
  SDL2_mixer,
  SDL2_net,
  alsa-lib,
  cpptrace,
  curl,
  expat,
  fltk,
  libdwarf,
  libsysprof-capture,
  libxkbcommon,
  portmidi,
  waylandpp,
  wxGTK32,
  xorg,
  zstd,

  withX11 ? stdenv.hostPlatform.isLinux,
  withWayland ? stdenv.hostPlatform.isLinux,
}:

stdenv.mkDerivation rec {
  pname = "odamex";
  version = "11.1.1";

  src = fetchFromGitHub {
    owner = "odamex";
    repo = "odamex";
    tag = version;
    hash = "sha256-UUUavIaU65vU80Bp2cVjHg8IubpA6qMqZmDYvTDjfEw=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    deutex
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    SDL2
    SDL2_mixer
    SDL2_net
    curl
    expat
    fltk
    libdwarf
    libsysprof-capture
    portmidi
    wxGTK32
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    cpptrace # tests are failing on darwin
  ]
  ++ lib.optionals withX11 [
    xorg.libX11
    xorg.xorgproto
  ]
  ++ lib.optionals withWayland [
    waylandpp
    libxkbcommon
  ];

  cmakeFlags = [
    (lib.cmakeBool "USE_INTERNAL_CPPTRACE" stdenv.hostPlatform.isDarwin)
    (lib.cmakeBool "USE_EXTERNAL_LIBDWARF" stdenv.hostPlatform.isDarwin)
  ];

  installPhase = ''
    runHook preInstall
  ''
  + (
    if stdenv.hostPlatform.isDarwin then
      ''
        mkdir -p $out/{Applications,bin}
        mv odalaunch/odalaunch.app $out/Applications
        makeWrapper $out/{Applications/odalaunch.app/Contents/MacOS,bin}/odalaunch
      ''
    else
      ''
        make install
      ''
  )
  + ''
    runHook postInstall
  '';

  meta = {
    homepage = "http://odamex.net/";
    description = "Client/server port for playing old-school Doom online";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
}
