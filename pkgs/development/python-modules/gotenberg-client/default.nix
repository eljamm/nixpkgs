{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  hatchling,
  httpx,
  typing-extensions,
}:
buildPythonPackage rec {
  pname = "gotenberg-client";
  version = "0.10.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "stumpylog";
    repo = "gotenberg-client";
    tag = version;
    hash = "sha256-eDYgKbNeNCIdENo6DVmcABRwP5JUMCJW7NtbPOA5aqg=";
  };

  nativeBuildInputs = [ hatchling ];

  propagatedBuildInputs = [
    httpx
  ]
  ++ lib.optionals (pythonOlder "3.11") [ typing-extensions ]
  ++ httpx.optional-dependencies.http2;

  pythonImportsCheck = [ "gotenberg_client" ];

  meta = with lib; {
    description = "Python client for interfacing with the Gotenberg API";
    homepage = "https://github.com/stumpylog/gotenberg-client";
    changelog = "https://github.com/stumpylog/gotenberg-client/blob/${src.tag}/CHANGELOG.md";
    license = licenses.mpl20;
    maintainers = with maintainers; [ leona ];
  };
}
