{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  jsonschema,
  whichcraft,
  pyqt5,
  pyqt6,
}:

buildPythonPackage rec {
  pname = "aab";
  version = "1.0.0-dev.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "glutanimate";
    repo = "anki-addon-builder";
    rev = "v${version}";
    hash = "sha256-92Xqxgb9MLhSIa5EN3Rdk4aJlRfzEWqKmXFe604Q354=";
  };

  build-system = [
    poetry-core
  ];

  dependencies = [
    jsonschema
    whichcraft
  ];

  optional-dependencies = {
    qt5 = [
      pyqt5
    ];
    qt6 = [
      pyqt6
    ];
  };

  pythonImportsCheck = [
    "aab"
  ];

  meta = {
    description = "Build tool for Anki add-ons";
    homepage = "https://github.com/glutanimate/anki-addon-builder";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ eljamm ];
  };
}
