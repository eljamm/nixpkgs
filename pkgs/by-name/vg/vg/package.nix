{
  lib,
  stdenv,
  fetchFromGitHub,

  # build-time
  pkg-config,
  automake,
  autoconf,
  libtool,

  # run-time
  cairo,
  expat,
  jansson,
  protobuf,
  zlib,
  zstd,
  libxdmcp,

  # deps
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
      --replace-fail "/bin/bash" "${stdenv.shell}" \
      --replace-fail "\$(shell arch)" "${stdenv.hostPlatform.uname.processor}"

    patchShebangs ./**/*.sh

    head deps/sdsl-lite/install.sh
  '';

  preBuild = ''
    mkdir -p {lib,include}
    rm -rf deps/sdsl-lite
    cp -R ${sdsl-lite}/opt deps/sdsl-lite
    cp -R ${sdsl-lite}/lib/*.a lib/
    cp -R ${sdsl-lite}/include/* include/
  '';

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    pkg-config

    # required by deps
    autoconf
    automake
    libtool
  ];

  buildInputs = [
    cairo
    zlib
    zstd
    protobuf
    jansson
    expat
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libxdmcp
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
