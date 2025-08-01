{
  lib,
  blinker,
  buildPythonPackage,
  cryptography,
  fetchFromGitHub,
  mock,
  pyjwt,
  pytestCheckHook,
  pythonAtLeast,
  pythonOlder,
  setuptools,

  # for passthru.tests
  django-allauth,
  django-oauth-toolkit,
  google-auth-oauthlib,
  requests-oauthlib,
}:

buildPythonPackage rec {
  pname = "oauthlib";
  version = "3.2.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "oauthlib";
    repo = "oauthlib";
    rev = "v${version}";
    hash = "sha256-KADS1pEaLYi86LEt2VVuz8FVTBANzxC8EeQLgGMxuBU=";
  };

  nativeBuildInputs = [ setuptools ];

  optional-dependencies = {
    rsa = [ cryptography ];
    signedtoken = [
      cryptography
      pyjwt
    ];
    signals = [ blinker ];
  };

  nativeCheckInputs = [
    mock
    pytestCheckHook
  ]
  ++ lib.flatten (lib.attrValues optional-dependencies);

  disabledTests = [
    # https://github.com/oauthlib/oauthlib/issues/877
    "test_rsa_bad_keys"
  ]
  ++ lib.optionals (pythonAtLeast "3.13") [
    "test_filter_params"
  ];

  pythonImportsCheck = [ "oauthlib" ];

  passthru.tests = {
    inherit
      django-allauth
      django-oauth-toolkit
      google-auth-oauthlib
      requests-oauthlib
      ;
  };

  meta = with lib; {
    changelog = "https://github.com/oauthlib/oauthlib/blob/${src.rev}/CHANGELOG.rst";
    description = "Generic, spec-compliant, thorough implementation of the OAuth request-signing logic";
    homepage = "https://github.com/oauthlib/oauthlib";
    license = licenses.bsd3;
    maintainers = with maintainers; [ prikhi ];
  };
}
