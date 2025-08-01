{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  python3,
  osi,
  cplex,
}:

stdenv.mkDerivation rec {
  pname = "fast-downward";
  version = "24.06.1";

  src = fetchFromGitHub {
    owner = "aibasel";
    repo = "downward";
    rev = "release-${version}";
    sha256 = "sha256-JwBdV44h6LAJeIjKHPouvb3ZleydAc55QiuaFGrFx1Y=";
  };

  nativeBuildInputs = [
    cmake
    python3.pkgs.wrapPython
  ];
  buildInputs = [
    python3
    osi
  ];

  cmakeFlags = lib.optionals osi.withCplex [ "-DDOWNWARD_CPLEX_ROOT=${cplex}/cplex" ];

  configurePhase = ''
    runHook preConfigure

    python build.py release

    runHook postConfigure
  '';

  postPatch = ''
    # Needed because the package tries to be too smart.
    export CC="$(which $CC)"
    export CXX="$(which $CXX)"
  '';

  installPhase = ''
    install -Dm755 builds/release/bin/downward $out/libexec/fast-downward/downward
    cp -r builds/release/bin/translate $out/libexec/fast-downward/
    install -Dm755 fast-downward.py $out/bin/fast-downward
    mkdir -p $out/${python3.sitePackages}
    cp -r driver $out/${python3.sitePackages}

    wrapPythonProgramsIn $out/bin "$out $pythonPath"
    wrapPythonProgramsIn $out/libexec/fast-downward/translate "$out $pythonPath"
    # Because fast-downward calls `python translate.py` we need to return wrapped scripts back.
    for i in $out/libexec/fast-downward/translate/.*-wrapped; do
      name="$(basename "$i")"
      name1="''${name#.}"
      name2="''${name1%-wrapped}"
      dir="$(dirname "$i")"
      dest="$dir/$name2"
      echo "Moving $i to $dest"
      mv "$i" "$dest"
    done

    substituteInPlace $out/${python3.sitePackages}/driver/arguments.py \
      --replace 'args.build = "release"' "args.build = \"$out/libexec/fast-downward\""
  '';

  meta = with lib; {
    description = "Domain-independent planning system";
    mainProgram = "fast-downward";
    homepage = "https://www.fast-downward.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ abbradar ];
  };
}
