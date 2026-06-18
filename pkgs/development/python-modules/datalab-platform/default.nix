{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-time
  qt6,

  # build-system
  setuptools,

  # dependencies
  fastapi,
  guidata,
  numpy,
  packaging,
  pandas,
  plotpy,
  psutil,
  pydantic,
  pywavelets,
  scikit-image,
  scipy,
  sigima,
  uvicorn,

  qtpy,

  # optional-dependencies
  babel,
  build,
  coverage,
  pre-commit,
  pylint,
  ruff,
  myst-parser,
  pydata-sphinx-theme,
  sphinx,
  sphinx-copybutton,
  sphinx-design,
  sphinx-intl,
  sphinx-sitemap,
  sphinxcontrib-svg2pdfconverter,
  opencv-python-headless,
  pyinstaller,
  pyqt6,
  httpx,
  pytest,
  pytest-xvfb,

  # tests
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "datalab-platform";
  version = "1.2.1";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "DataLab-Platform";
    repo = "DataLab";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rJDA5qYv2LYMyrckxNy63Gqn8HYU62qG0OAioztKGtA=";
  };

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
  ];

  build-system = [
    setuptools
  ];

  dependencies = [
    fastapi
    guidata
    numpy
    packaging
    pandas
    plotpy
    psutil
    pydantic
    pywavelets
    scikit-image
    scipy
    sigima
    uvicorn
  ]
  ++ finalAttrs.passthru.optional-dependencies.qt;

  optional-dependencies = {
    dev = [
      babel
      build
      coverage
      pre-commit
      pylint
      ruff
    ];
    doc = [
      myst-parser
      pydata-sphinx-theme
      sphinx
      sphinx-copybutton
      sphinx-design
      sphinx-intl
      sphinx-sitemap
      sphinxcontrib-svg2pdfconverter
    ];
    exe = [
      opencv-python-headless
      pyinstaller
      pyqt6
    ];
    opencv = [
      opencv-python-headless
    ];
    qt = [
      pyqt6
    ];
    test = [
      httpx
      pytest
      pytest-xvfb
    ];
  };

  pythonRelaxDeps = [
    "guidata"
    "plotpy"
    "scipy"
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ]
  ++ finalAttrs.passthru.optional-dependencies.test;

  pytestFlags = [
    "--collect-only"
  ];

  pythonImportsCheck = [
    "datalab"
  ];

  meta = {
    description = "Open-source Platform for Scientific and Technical Data Processing and Visualization";
    homepage = "https://github.com/DataLab-Platform/DataLab";
    changelog = "https://github.com/DataLab-Platform/DataLab/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
