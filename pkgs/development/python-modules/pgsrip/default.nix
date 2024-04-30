{ lib
, buildPythonPackage
, fetchFromGitHub
, poetry-core
, babelfish
, cleanit
, click
, numpy
, opencv4
, pysrt
, pytesseract
, trakit
}:

buildPythonPackage rec {
  pname = "pgsrip";
  version = "0.1.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ratoaq2";
    repo = "pgsrip";
    rev = version;
    hash = "sha256-fqFIlupcxqsCVjfzfutI1ht4Rts2kXp+DRrRP2QSjCI=";
  };

  nativeBuildInputs = [
    poetry-core
  ];

  dependencies = [
    babelfish
    cleanit
    click
    numpy
    opencv4
    pysrt
    pytesseract
    trakit
  ];

  patchPhase = ''
    substituteInPlace pyproject.toml --replace "opencv-python" "opencv"
  '';

  meta = {
    changelog = "https://github.com/ratoaq2/pgsrip/releases/tag/${version}";
    description = "Rip your PGS subtitles";
    homepage = "https://github.com/ratoaq2/pgsrip";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
