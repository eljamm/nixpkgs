{
  lib,
  fetchFromGitHub,
  fetchFromBitbucket,
  gcc13Stdenv,

  # dependencies
  boost,
  cmake,
  eigen,
  ninja,
  opensta,
  python3,
  qt6,
  readline,
  cxxopts,
  tomlplusplus,
}:

let
  strutilspp = fetchFromBitbucket {
    owner = "trcwm";
    repo = "strutilspp";
    rev = "e1b43c2fdeea765a613ae4d509a2016e5b3c2d19";
    hash = "sha256-gd1r/6FlfUt7lgp+ZGphbeUG78wNJiJ7WbRKSJigrfI=";
  };
  tinysvgpp = fetchFromBitbucket {
    owner = "trcwm";
    repo = "tinysvgpp";
    rev = "851ab2e2704871cc2a91afb99110a81d241233f0";
    hash = "sha256-KEeW62VPn+sKJ3SOv7idfAQ+EkeXfdZJzGpUfgq2zFQ=";
  };
in
gcc13Stdenv.mkDerivation {
  pname = "lunapnr";
  version = "0-unstable-2024-03-25";

  src = fetchFromGitHub {
    owner = "asicsforthemasses";
    repo = "LunaPnR";
    rev = "c3ea6c";
    hash = "sha256-oEYJ/+vHDY2isTcTNBMcFT2ASjmgGpmdlmJ6NrUJi+Q=";
  };

  patchPhase = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'enable_testing()' ''' \
      --replace-fail 'add_subdirectory(test)' ''' \
      --replace-fail 'DESTINATION ''${LUNA_INSTALL_PREFIX}/bin)' "DESTINATION $out/bin)"

    substituteInPlace gui/src/mainwindow.cpp \
      --replace-fail 'settings.value("opensta_location", "/usr/local/bin/sta").toString()' 'QString("${opensta}/bin/sta")'

    # Remove CPM calls to download dependencies
    substituteInPlace tools/CMakeLists.txt \
      --replace-fail 'set(CPM_DOWNLOAD_VERSION 0.38.2)' ''' \
      --replace-fail 'CPMAddPackage("bb:trcwm/strutilspp#main")' ''' \
      --replace-fail 'CPMAddPackage("gh:jarro2783/cxxopts#v3.1.1")' ''' \
      --replace-fail 'CPMAddPackage("gh:marzer/tomlplusplus#v3.3.0")' '''

    substituteInPlace core/CMakeLists.txt \
      --replace-fail 'set(CPM_DOWNLOAD_VERSION 0.38.2)' ''' \
      --replace-fail 'CPMAddPackage("bb:trcwm/tinysvgpp#main")' ''' \
      --replace-fail 'CPMAddPackage("bb:trcwm/strutilspp#main")' ''' \
      --replace-fail 'CPMAddPackage("gh:marzer/tomlplusplus#v3.3.0")' '''

    substituteInPlace gui/CMakeLists.txt \
      --replace-fail 'CPMAddPackage("gh:marzer/tomlplusplus#v3.3.0")' '''

    # Add CPM dependencies
    cp -R --no-preserve=mode,ownership ${cxxopts.src} cxxopts
    cp -R --no-preserve=mode,ownership ${tomlplusplus.src} tomlplusplus
    cp -R --no-preserve=mode,ownership ${strutilspp} strutilspp
    cp -R --no-preserve=mode,ownership ${tinysvgpp} tinysvgpp

    cat >> CMakeLists.txt << EOF
    add_subdirectory(strutilspp)
    add_subdirectory(cxxopts)
    add_subdirectory(tomlplusplus)
    add_subdirectory(tinysvgpp)
    EOF
  '';

  buildInputs = [
    qt6.qtbase
    boost
    eigen
  ];
  propagatedBuildInputs = [ python3 ];
  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    cmake
    ninja
    readline
  ];

  cmakeFlags = [ "-DReadline_ROOT_DIR=${lib.getDev readline}" ];

  meta = {
    description = "A robust place and route tool intended for IC processes with features sizes greater than 100nm";
    homepage = "https://www.asicsforthemasses.com";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
  };
}
