{
  lib,
  stdenv,
  fetchFromGitea,
  nix-update-script,

  not-forking,
  which,
  tcl-9_0,
  tcl9Packages,
  perl,
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
  ];

  buildInputs = [
    tcl-9_0
    tcl9Packages.tclx
  ];

  preBuild = ''
    # TODO: remove
    make doctor
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
