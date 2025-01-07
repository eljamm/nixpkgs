{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,

  # runtime
  editables,
  packaging,
  pathspec,
  pluggy,
  tomli,
  trove-classifiers,

  # tests
  build,
  python,
  requests,
  virtualenv,
}:

buildPythonPackage rec {
  pname = "hatchling";
  format = "pyproject";
  version = "1.27.0";
  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-lxwpbZgZq7OBERL8UsepdRyNOBiY82Uzuxb5eR6UH9Y=";
  };

  # listed in backend/pyproject.toml
  propagatedBuildInputs = [
    editables
    packaging
    pathspec
    pluggy
    trove-classifiers
  ] ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  pythonImportsCheck = [
    "hatchling"
    "hatchling.build"
  ];

  # tries to fetch packages from the internet
  doCheck = false;

  # listed in /backend/tests/downstream/requirements.txt
  nativeCheckInputs = [
    build
    requests
    virtualenv
  ];

  preCheck = ''
    export HOME=$TMPDIR
  '';

  checkPhase = ''
    runHook preCheck
    ${python.interpreter} tests/downstream/integrate.py
    runHook postCheck
  '';

  meta = with lib; {
    description = "Modern, extensible Python build backend";
    mainProgram = "hatchling";
    homepage = "https://hatch.pypa.io/latest/";
    changelog = "https://github.com/pypa/hatch/releases/tag/hatchling-v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [
      hexa
      ofek
    ];
  };
}
