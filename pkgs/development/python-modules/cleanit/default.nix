{ lib
, buildPythonPackage
, fetchFromGitHub
, appdirs
, babelfish
, chardet
, click
, jsonschema
, pysrt
, pyyaml
, poetry-core
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "cleanit";
  version = "0.4.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ratoaq2";
    repo = "cleanit";
    rev = version;
    hash = "sha256-tFVZgdL8p4YLBPyAsJ08g3ZQjYuezqEeQzLxLdnVeiI=";
  };

  nativeBuildInputs = [
    poetry-core
  ];

  dependencies = [
    appdirs
    babelfish
    chardet
    click
    jsonschema
    pysrt
    pyyaml
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  meta = {
    changelog = "https://github.com/ratoaq2/cleanit/releases/tag/${version}";
    description = "Command line tool that helps you to keep your subtitles clean";
    homepage = "https://github.com/ratoaq2/cleanit";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
  };
}
