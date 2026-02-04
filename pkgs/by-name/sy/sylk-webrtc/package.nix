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
    installDeps() {
      local cache="$1"

      fixup-yarn-lock yarn.lock

      yarn config --offline set yarn-offline-mirror "$cache"
      yarn install --offline --frozen-lockfile --ignore-engines --ignore-scripts

      patchShebangs node_modules/
    }

    installDeps $yarnOfflineCache

    pushd app
    installDeps ${finalAttrs.passthru.appOfflineCache}
    popd
  '';

  postFixup = ''
    mkdir -p $out/share
    mv $out/lib/node_modules/Sylk $out/share/Sylk

    rm -rf $out/share/Sylk/{.parcel-cache,node_modules}
    cp -R node_modules $out/share/Sylk
    cp -R app/node_modules $out/share/Sylk/app

    ${lib.optionalString withElectron ''
      makeWrapper ${lib.getExe electron} $out/bin/sylk-webrtc \
        --add-flags $out/share/Sylk/app \
        --inherit-argv0
    ''}

    ${lib.optionalString (!withElectron) ''
      makeWrapper ${lib.getExe serve} $out/bin/sylk-webrtc \
        --prefix PATH : ${lib.makeBinPath [ xsel ]} \
        --chdir $out/share/Sylk \
        --inherit-argv0
    ''}
  '';

  # required for electron
  passthru.appOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/app/yarn.lock";
    hash = "sha256-S9L/rveTuXF2vSqSDu+NlV5vP5f28lda/KMGU8iS1Zo=";
  };

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
