{
  lib,
  stdenv,
  fetchFromGitea,
  nix-update-script,

  not-forking,
  which,
  tcl-8_6,
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
    fossil

    tcl-8_6
    tcl8Packages.tclx
  ];

  buildInputs = [
    tcl-8_6
    tcl8Packages.tclx

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

  makeFlags = [
    "CACHE_DIR=/tmp"
    "NOTFORK_UPDATE=0"
  ];

  env = {
    HOME = "/tmp";
    USER = "nixbld";
  };

  # LumoSQL downloads SQLite source from sqlite.org via `not-fork` during the build.
  # This requires network access (fetcher setup) or pre-populating the not-fork cache.
  # See the `not-fork` cache format and `NOTFORK_MIRROR` for offline build options.

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
