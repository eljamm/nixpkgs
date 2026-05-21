{
  lib,
  stdenv,
  fetchFromGitHub,

  # build-time
  autoconf,
  automake,
  bison,
  cmake,
  flex,
  gettext,
  hostname,
  libtool,
  perl,
  pkg-config,
  python3,
  util-linux,
  which,
  whoami,

  # run-time
  boost,
  bzip2,
  cairo,
  curl,
  expat,
  jansson,
  libxdmcp,
  ncurses,
  openssl,
  protobuf,
  xz,
  zlib,
  zstd,
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
    substituteInPlace \
      Makefile \
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

    patch -p1 -d deps/libbdsg -i ${./0001-Use-order-only-prerequisite-for-making-sure-dirs-exi.patch}

    pushd deps/htslib
      PACKAGE_VERSION=$(./version.sh)
      echo '#define HTSCODECS_VERSION_TEXT "$PACKAGE_VERSION"' > ./htscodecs/htscodecs/version.h
    popd
  '';

  dontUseCmake = true;
  dontConfigure = true;
  enableParallelBuilding = false; # fickle and may cause issues

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    autoconf
    automake
    bison
    cmake
    finalAttrs.passthru.customPython
    flex
    gettext
    hostname
    libtool
    perl
    pkg-config
    which
    whoami
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    util-linux # rev, and possibly others
  ];

  buildInputs = [
    boost
    bzip2
    cairo
    curl
    expat
    jansson
    ncurses
    openssl
    protobuf
    xz
    zlib
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libxdmcp
  ];

  preBuild = ''
    # src/aligner.cpp:2489:1: fatal error: opening dependency file
    # obj/aligner.d: No such file or directory
    mkdir -p obj/{pic/algorithms,algorithms,config,io,subcommand,unittest/support}
  '';

  passthru.customPython = python3.withPackages (
    ps: with ps; [
      pybind11
    ]
  );

  # deps/elfutils
  NIX_CFLAGS_COMPILE = toString [
    "-Wno-error=stringop-overflow"
    "-Wno-error=unterminated-string-initialization"
  ];

  makeFlags = [
    # don't build statically
    "START_STATIC="
    "END_STATIC="
  ];

  # no install target
  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}

    cp bin/* $out/bin/
    cp -R lib/lib{handlegraph,vgio,hts,deflate}.so* $out/lib/

    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup

    for bin in $out/bin/* ; do
      patchelf --allowed-rpath-prefixes /nix/store --shrink-rpath $bin
      patchelf --set-rpath "$out/lib:$(patchelf --print-rpath $bin)" $bin
    done

    # remove debugging symbols that make the binary bloated in size
    strip -d $out/bin/vg

    runHook postFixup
  '';

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
