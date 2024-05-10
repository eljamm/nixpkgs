{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, obs-studio
, onnxruntime
, opencv
, qt6
, curl
}:

stdenv.mkDerivation rec {
  pname = "obs-backgroundremoval";
  version = "1.1.13-2";

  src = fetchFromGitHub {
    owner = "occ-ai";
    repo = "obs-backgroundremoval";
    rev = "94be8c35fe077be93a6f5ef347a802295a36dddd";
    hash = "sha256-qnxDNeTWQYiRMqT6jNp8GC8ef6aaAAY+OXAak54dVc8=";
  };

  nativeBuildInputs = [ cmake ninja ];
  buildInputs = [ obs-studio onnxruntime opencv qt6.qtbase curl ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "--preset linux-x86_64"
    "-DCMAKE_MODULE_PATH:PATH=${src}/cmake"
    "-DUSE_SYSTEM_ONNXRUNTIME=ON"
    "-DUSE_SYSTEM_OPENCV=ON"
    "-DDISABLE_ONNXRUNTIME_GPU=ON"
  ];

  buildPhase = ''
    cd ..
    cmake --build build_x86_64 --parallel
  '';

  installPhase = ''
    cmake --install build_x86_64 --prefix "$out"
  '';

  meta = with lib; {
    description = "OBS plugin to replace the background in portrait images and video";
    homepage = "https://github.com/royshil/obs-backgroundremoval";
    maintainers = with maintainers; [ zahrun ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
