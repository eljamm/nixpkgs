{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  flit-core,

  # optional-dependencies
  intersphinx-registry,
  platformdirs,
  requests,
  requests-cache,
  sphinx,
  mypy,
  pytest,
  pytest-xdist,
  types-requests,

  # tests
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "intersphinx-registry";
  version = "0.2705.27";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Quansight-labs";
    repo = "intersphinx_registry";
    tag = finalAttrs.version;
    hash = "sha256-yFpk3NZO2iCjuJ43WvssbDYxNJ6G6KfY5pcTCilsGQs=";
  };

  build-system = [
    flit-core
  ];

  optional-dependencies = {
    cli = [
      intersphinx-registry
    ];
    lookup = [
      platformdirs
      requests
      requests-cache
      sphinx
    ];
    tests = [
      intersphinx-registry
      mypy
      pytest
      pytest-xdist
      types-requests
    ];
  };

  nativeCheckInputs = [
    mypy
    pytest-xdist
    pytestCheckHook
    sphinx
  ];

  # TODO: lots of failing tests
  doCheck = false;

  pythonImportsCheck = [
    "intersphinx_registry"
  ];

  meta = {
    description = "";
    homepage = "https://github.com/Quansight-labs/intersphinx_registry";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
