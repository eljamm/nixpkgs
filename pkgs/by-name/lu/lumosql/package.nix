{
  lib,
  stdenv,
  fetchFromGitea,
  nix-update-script,

  not-forking,
  which,
  tcl-8_5,
  tcl8Packages,
  perl,

  libsodium,
  fossil,
  readline,
  ncurses,
  zlib,

  encryptionSupport ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lumosql";
  version = "0.83";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "LumoSQL";
    repo = "lumosql";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KK/1Uf1sB2f1BACl1ivL7+TL/eAn6MvGfob4eXgzakc=";
  };

  nativeBuildInputs = [
    not-forking
    which
    perl

    tcl-8_5
    tcl8Packages.tclx
  ];

  buildInputs = [
    tcl-8_5
    tcl8Packages.tclx

    fossil
    readline
    ncurses
    zlib
  ]
  ++ lib.optionals encryptionSupport [
    libsodium
  ];

  preBuild = ''
    make Makefile.options
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "";
    homepage = "https://codeberg.org/LumoSQL/lumosql";
    mainProgram = "lumosql";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
