{
  lib,
  stdenv,
  fetchFromGitea,
  nix-update-script,
  perl,
  perlPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "not-forking";
  version = "0.5";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "not-forking";
    repo = "not-forking";
    tag = "version-${finalAttrs.version}";
    hash = "sha256-225o/J626N2I4h0lUTGnoIwWJ40oqhz1gh0cOIGd0ew=";
  };

  nativeBuildInputs = [
    perl
    perlPackages.TextGlob
  ];

  preBuild = ''
    perl Makefile.PL PREFIX="$out"
  '';

  postFixup = ''
    # make Perl modules (NotFork::*) findable by the scripts at runtime
    for f in $out/bin/*; do
      substituteInPlace "$f" \
        --replace-fail \
          'use FindBin qw($Script);' \
          'use FindBin qw($Script); use lib "'$out'/'${perl.libPrefix}'/'${perl.version}'";'
    done
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Software reproducibility tool";
    homepage = "https://codeberg.org/not-forking/not-forking";
    mainProgram = "not-forking";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
