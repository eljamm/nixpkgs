{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? null,
}:

assert cudaSupport -> cudaPackages != null;

stdenv.mkDerivation rec {
  pname = "umpire";
  version = "2025.03.1";

  src = fetchFromGitHub {
    owner = "LLNL";
    repo = "umpire";
    rev = "v${version}";
    hash = "sha256-MHvJRXAMV64GxGgCJjQPlaNyxVjBvyQXogbla9UMFL8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = lib.optionals cudaSupport (
    with cudaPackages;
    [
      cudatoolkit
      cuda_cudart
    ]
  );

  cmakeFlags = lib.optionals cudaSupport [
    "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
    "-DENABLE_CUDA=ON"
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
  ];

  meta = with lib; {
    description = "Application-focused API for memory management on NUMA & GPU architectures";
    homepage = "https://github.com/LLNL/Umpire";
    maintainers = with maintainers; [ sheepforce ];
    license = with licenses; [ mit ];
    platforms = [ "x86_64-linux" ];
  };
}
