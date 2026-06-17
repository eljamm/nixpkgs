{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatch-nodejs-version,
  hatchling,
  jupyter-core,
  tomli,
  traitlets,
  build,
  hatch,
  mypy,
  pre-commit,
  ruff,
  copier,
  coverage,
  jinja2-time,
  pytest,
  pytest-check-links,
  pytest-cov,
  nix-update-script,
}:

buildPythonPackage (finalAttrs: {
  pname = "jupyter-builder";
  version = "1.0.2";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "jupyterlab";
    repo = "jupyter-builder";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hUAsoSER/atZy69qSGuIDzHekXcLExFwsg74C3e5Jj8=";
  };

  build-system = [
    hatch-nodejs-version
    hatchling
  ];

  dependencies = [
    jupyter-core
    tomli
    traitlets
  ];

  optional-dependencies = {
    dev = [
      build
      hatch
      mypy
      pre-commit
      ruff
    ];
    test = [
      copier
      coverage
      jinja2-time
      pytest
      pytest-check-links
      pytest-cov
    ];
  };

  pythonImportsCheck = [
    "jupyter_builder"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Build tools for JupyterLab (and remixes";
    homepage = "https://github.com/jupyterlab/jupyter-builder";
    changelog = "https://github.com/jupyterlab/jupyter-builder/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = with lib.licenses; [
      bsd3
      isc
      mit
    ];
    maintainers = with lib.maintainers; [ ];
  };
})
