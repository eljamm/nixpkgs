{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cargo-tauri,
  pkg-config,
  wrapGAppsHook4,
  atk,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  libsoup_3,
  openssl,
  pango,
  webkitgtk_4_1,
  zstd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "novy-wave";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "NovyWave";
    repo = "NovyWave";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FUlQleS9Oft/KlDuAV9qS73k1lVfOhVJOZc7O3QhaZ8=";
  };

  cargoHash = "sha256-luKaenOdxDM0vtnAclUSxhUoeXcP6YjC79rYNrRXNgs=";

  patchPhase = ''
    # disable updater artifact creation to skip private key requirement
    substituteInPlace src-tauri/tauri.conf.json \
      --replace-fail \
        '"createUpdaterArtifacts": true,' \
        '"createUpdaterArtifacts": false,'
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    libsoup_3
    openssl
    pango
    webkitgtk_4_1
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
    FRONTEND_BUILD_ID = "release";
    CACHE_BUSTING = 1;
  };

  preBuild = ''
    cargo build --release -p backend

    # TODO: frontend requires `mzoon` dependency
    # for now, create stub directories so tauri.conf.json validation passes
    mkdir -p frontend/pkg plugins/dist _api
  '';

  meta = {
    description = "Waveform viewer for VCD, FST, and GHW files";
    homepage = "https://github.com/NovyWave/NovyWave";
    changelog = "https://github.com/NovyWave/NovyWave/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    mainProgram = "novy-wave";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
