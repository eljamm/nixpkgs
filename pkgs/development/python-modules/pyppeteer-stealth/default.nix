{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pyppeteer,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyppeteer-stealth";
  version = "0-unstable-2021-03-04";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "MeiK2333";
    repo = "pyppeteer_stealth";
    rev = "0f04fcfbf596052bbbe102d5e68f82956af57338";
    hash = "sha256-/Ja51TicRytMrL3z/kultuQjhlq3m7IHU/CLY3EqdN8=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    pyppeteer
  ];

  pythonImportsCheck = [
    "pyppeteer_stealth"
  ];

  meta = {
    description = "Pyppeteer stealth plugin, attempts to look like a normal browser";
    homepage = "https://github.com/MeiK2333/pyppeteer_stealth";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
