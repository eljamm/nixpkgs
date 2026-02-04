{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  fixup-yarn-lock,
  node-gyp-build,
  nodejs,
  writableTmpDirAsHomeHook,
  electron,
  yarnBuildHook,
  yarnConfigHook,
  yarnInstallHook,

  withElectron ? false,
  serve,
  xsel,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sylk-webrtc";
  version = "3.8.0";

  src = fetchFromGitHub {
    owner = "AGProjects";
    repo = "sylk-webrtc";
    rev = finalAttrs.version;
    hash = "sha256-AJbZDAEqGfVPuo+My8wxfFWVPelO6XK2pKsglmLyRTw=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-VY97NPnT1225l6SLyTI3qITBGF7rqE5xz6UVVucblcU=";
  };

  nativeBuildInputs = [
    fixup-yarn-lock
    node-gyp-build
    nodejs # needed for executing package.json scripts
    writableTmpDirAsHomeHook
    yarnBuildHook
    yarnConfigHook
    yarnInstallHook
    electron
  ];

  dontConfigure = true;

  yarnBuildScript = if withElectron then "electron" else "build";
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  preBuild = ''
    fixup-yarn-lock yarn.lock

    yarn config --offline set yarn-offline-mirror $yarnOfflineCache

    yarn install \
      --offline \
      --frozen-lockfile \
      --ignore-engines \
      --ignore-scripts

    yarn install \
      --offline

    patchShebangs node_modules/
  '';

  postFixup = ''
    rm -rf $out/lib/node_modules/Sylk/.parcel-cache

    ${lib.optionalString withElectron ''
      makeWrapper ${lib.getExe electron} $out/bin/sylk-webrtc \
        --add-flags $out/lib/node_modules/Sylk/app \
        --inherit-argv0
    ''}

    ${lib.optionalString (!withElectron) ''
      makeWrapper ${lib.getExe serve} $out/bin/sylk-webrtc \
        --prefix PATH : ${lib.makeBinPath [ xsel ]} \
        --chdir $out/lib/node_modules/Sylk
        --inherit-argv0
    ''}
  '';

  meta = {
    description = "Sylk WebRTC client";
    homepage = "https://github.com/AGProjects/sylk-webrtc";
    changelog = "https://github.com/AGProjects/sylk-webrtc/blob/${finalAttrs.src.rev}/changelog.txt";
    mainProgram = "sylk-webrtc";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.all;
    teams = with lib.teams; [ ngi ];
  };
})
