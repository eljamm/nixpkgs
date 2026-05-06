{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cargo-tauri,
  pkg-config,
  wrapGAppsHook3,
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

  nativeBuildInputs = [
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook3
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
