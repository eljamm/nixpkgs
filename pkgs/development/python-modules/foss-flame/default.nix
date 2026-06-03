{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,

  # dependencies
  jsonschema,
  license-expression,
  osadl-matrix,
  pyyaml,
  spdx-license-list,
}:

buildPythonPackage (finalAttrs: {
  pname = "foss-flame";
  version = "0.21.8";
  __structuredAttrs = true;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "hesa";
    repo = "foss-licenses";
    tag = finalAttrs.version;
    hash = "sha256-EEpw1OJKMAlYu8EFxu+/AWFMIMO25TCx2jdT1rxNhOo=";
  };

  sourceRoot = "${finalAttrs.src.name}/python";

  build-system = [
    setuptools
  ];

  dependencies = [
    jsonschema
    license-expression
    osadl-matrix
    pyyaml
    spdx-license-list
  ];

  meta = {
    description = "License meta data: data and python module/cli";
    homepage = "https://github.com/hesa/foss-licenses";
    changelog = "https://github.com/hesa/foss-licenses/releases/tag/${finalAttrs.src.tag}";
    mainPackage = "flame";
    license = with lib.licenses; [
      bsd2
      cc-by-40
      gpl3Plus
    ];
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
