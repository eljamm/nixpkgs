{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  hatch-vcs,
  hatchling,

  # dependencies
  pytest,

  # tests
  pytest-xdist,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-reportlog";
  version = "1.0.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-reportlog";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YfHONQ4fURPDUdF1Q1rTK543sHOAK9dyrFgQrXidAaY=";
  };

  build-system = [
    hatch-vcs
    hatchling
  ];

  dependencies = [
    pytest
  ];

  nativeCheckInputs = [
    pytest-xdist
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "pytest_reportlog"
  ];

  meta = {
    description = "Replacement for the --resultlog option, focused in simplicity and extensibility";
    homepage = "https://github.com/pytest-dev/pytest-reportlog";
    changelog = "https://github.com/pytest-dev/pytest-reportlog/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
