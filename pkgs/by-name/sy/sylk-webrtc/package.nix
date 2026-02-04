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
  yarn,
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

  # required for electron
  passthru.appOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/app/yarn.lock";
    hash = "sha256-S9L/rveTuXF2vSqSDu+NlV5vP5f28lda/KMGU8iS1Zo=";
  };

  outputs = [
    "out"
    "deps"
  ]
  ++ lib.optional withElectron "electronDeps";

  nativeBuildInputs = [
    fixup-yarn-lock
    node-gyp-build
    nodejs # needed for executing package.json scripts
    writableTmpDirAsHomeHook
    yarnBuildHook
    yarnConfigHook
    yarnInstallHook
  ];

  dontConfigure = true;
  yarnBuildScript = if withElectron then "electron" else "build";

  preBuild = ''
    originalOfflineMirror=$(yarn config --offline get yarn-offline-mirror)

    installDeps() {
      local cache="$1"
      local output="$2"
      fixup-yarn-lock yarn.lock
      yarn config --offline set yarn-offline-mirror "$cache"
      yarn install --offline --frozen-lockfile --ignore-engines --ignore-scripts
      patchShebangs node_modules/
      mkdir -p $output
      cp -R node_modules $output
    }

    installDeps $yarnOfflineCache $deps

    ${lib.optionalString withElectron ''
      pushd app
        installDeps ${finalAttrs.passthru.appOfflineCache} $electronDeps
      popd
    ''}

    yarn config --offline set yarn-offline-mirror $originalOfflineMirror
  '';

  postFixup = ''
    mkdir -p $out/share
    mv $out/lib/node_modules/Sylk $out/share/Sylk

    rm -rf $out/lib
    rm -rf $out/share/Sylk/.parcel-cache
    rm -rf $out/share/Sylk/node_modules

    ln -s $electronDeps/node_modules $out/share/Sylk/app/node_modules
    ln -s $deps/node_modules $out/share/Sylk/node_modules

    ${lib.optionalString withElectron ''
      makeWrapper ${lib.getExe electron} $out/bin/sylk-webrtc \
        --add-flags $out/share/Sylk/app \
        --inherit-argv0
    ''}

    ${lib.optionalString (!withElectron) ''
      makeWrapper ${lib.getExe yarn} $out/bin/sylk-webrtc \
        --add-flags "run node_modules/.bin/parcel serve ./src/index.html" \
        --chdir $out/share/Sylk \
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
