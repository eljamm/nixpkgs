{
  lib,
  buildPythonPackage,
  fetchPypi,
  gitMinimal,
  numpy,
  packaging,
  pytest,
  pytestCheckHook,
  pythonOlder,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "pytest-doctestplus";
  version = "1.2.1";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-JHKoosjOo00vZfZJlUP663SO7LWcWXhS/ZiDm0cwdnk=";
  };

  postPatch = ''
    substituteInPlace pytest_doctestplus/plugin.py \
      --replace-fail '"git"' '"${lib.getExe gitMinimal}"'
  '';

  nativeBuildInputs = [ setuptools-scm ];

  buildInputs = [ pytest ];

  propagatedBuildInputs = [
    packaging
    setuptools
  ];

  nativeCheckInputs = [
    numpy
    pytestCheckHook
  ];

  disabledTests = [
    # ERROR: usage: __main__.py [options] [file_or_dir] [file_or_dir] [...]
    # __main__.py: error: unrecognized arguments: --remote-data
    "test_remote_data_url"
    "test_remote_data_float_cmp"
    "test_remote_data_ignore_whitespace"
    "test_remote_data_ellipsis"
    "test_remote_data_requires"
    "test_remote_data_ignore_warnings"
  ];

  meta = with lib; {
    description = "Pytest plugin with advanced doctest features";
    homepage = "https://astropy.org";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
