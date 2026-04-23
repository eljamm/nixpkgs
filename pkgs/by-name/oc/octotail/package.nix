{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "octotail";
  version = "1.0.17";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "getbettr";
    repo = "octotail";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UC+3XLls8WL4yquCYc8QsPTrKrO5gO8v2NUTM3dMy18=";
  };

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    fake-useragent
    mitmproxy
    pygithub
    pykka
    pyppeteer
    pyppeteer-stealth
    pyxdg
    returns
    rich
    shellingham
    termcolor
    typer
    websockets
  ];

  pythonImportsCheck = [
    "octotail"
  ];

  meta = {
    description = "Live tail GitHub Action runs on `git push`";
    homepage = "https://github.com/getbettr/octotail";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ eljamm ];
    mainProgram = "octotail";
  };
})
