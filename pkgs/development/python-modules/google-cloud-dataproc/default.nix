{
  lib,
  buildPythonPackage,
  fetchPypi,
  google-api-core,
  grpc-google-iam-v1,
  mock,
  libcst,
  proto-plus,
  protobuf,
  pytestCheckHook,
  pytest-asyncio,
  pythonOlder,
  setuptools,
}:

buildPythonPackage rec {
  pname = "google-cloud-dataproc";
  version = "5.21.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    pname = "google_cloud_dataproc";
    inherit version;
    hash = "sha256-LSoMxquZrJVB9z0uIRqFH6TQp18btRsjwk3vyGzWxPo=";
  };

  build-system = [ setuptools ];

  dependencies = [
    google-api-core
    grpc-google-iam-v1
    libcst
    proto-plus
    protobuf
  ]
  ++ google-api-core.optional-dependencies.grpc;

  nativeCheckInputs = [
    mock
    pytestCheckHook
    pytest-asyncio
  ];

  disabledTests = [
    # Test requires credentials
    "test_list_clusters"
  ];

  pythonImportsCheck = [
    "google.cloud.dataproc"
    "google.cloud.dataproc_v1"
  ];

  meta = with lib; {
    description = "Google Cloud Dataproc API client library";
    homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/google-cloud-dataproc";
    changelog = "https://github.com/googleapis/google-cloud-python/blob/google-cloud-dataproc-v${version}/packages/google-cloud-dataproc/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
