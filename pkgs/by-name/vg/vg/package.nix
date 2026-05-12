{
  lib,
  stdenv,
  fetchFromGitHub,

  # build-time
  pkg-config,
  automake,
  autoconf,
  libtool,
  cmake,
  util-linux,
  python3,
  which,
  bison,

  # run-time
  cairo,
  expat,
  jansson,
  protobuf,
  zlib,
  zstd,
  libxdmcp,
  openssl,
  xz,
  curl,

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

    substituteInPlace \
      deps/libbdsg/bdsg/deps/pybind11/tests/CMakeLists.txt \
      deps/vcflib/CMakeLists.txt \
        --replace-fail \
          "find_package(pybind11 " \
          "set(PYBIND11_FINDPYTHON ON)
          find_package(pybind11 "

    patchShebangs ./
    patchShebangs deps/
  '';

  dontUseCmake = true;
  dontConfigure = true;

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    pkg-config

    # required by deps
    cmake
    autoconf
    automake
    libtool
    util-linux # rev, and possibly others
    finalAttrs.passthru.customPython
    which # TODO: replace all instances with absolute path
    bison
  ];

  buildInputs = [
    cairo
    zlib
    zstd
    protobuf
    jansson
    expat
    openssl
    xz
    curl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libxdmcp
  ];

  preBuild = ''
    pushd deps/htslib
      PACKAGE_VERSION=$(./version.sh)
      echo '#define HTSCODECS_VERSION_TEXT "$PACKAGE_VERSION"' > ./htscodecs/htscodecs/version.h
    popd
  '';

  passthru.customPython = python3.withPackages (
    ps: with ps; [
      pybind11
    ]
  );

  cmakeFlags = [
    # deps/libbdsg
    "-DPython_EXECUTABLE=${lib.getExe finalAttrs.passthru.customPython}"
    # deps/vcflib
    "-DPYTHON_EXECUTABLE=${lib.getExe finalAttrs.passthru.customPython}"
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
