{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,

  cmake,
  deutex,
  makeWrapper,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,

  SDL2,
  SDL2_mixer,
  SDL2_net,
  alsa-lib,
  cpptrace,
  curl,
  expat,
  fltk,
  libdwarf,
  libsysprof-capture,
  libxkbcommon,
  portmidi,
  waylandpp,
  wxGTK32,
  xorg,
  zstd,

  nix-update-script,

  withX11 ? stdenv.hostPlatform.isLinux,
  withWayland ? stdenv.hostPlatform.isLinux,
}:

let
  cpptrace' = cpptrace.overrideAttrs {
    # tests are failing on darwin
    # https://hydra.nixos.org/build/310535948
    doCheck = !stdenv.hostPlatform.isDarwin;
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "odamex";
  version = "11.1.1";

  src = fetchFromGitHub {
    owner = "odamex";
    repo = "odamex";
    tag = finalAttrs.version;
    hash = "sha256-UUUavIaU65vU80Bp2cVjHg8IubpA6qMqZmDYvTDjfEw=";
    fetchSubmodules = true;
  };

  patches = [
    # fix file-open panel on Darwin
    # https://github.com/odamex/odamex/pull/1402
    # TODO: remove on next release
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/odamex/odamex/pull/1402.patch";
      hash = "sha256-JrcQ0rYkaFP5aKNWeXbrY2TN4r8nHpue19qajNXJXg4=";
    })
  ];

  nativeBuildInputs = [
    cmake
    copyDesktopItems
    deutex
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    SDL2
    SDL2_mixer
    SDL2_net
    cpptrace'
    curl
    expat
    fltk
    libdwarf
    libsysprof-capture
    portmidi
    wxGTK32
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ]
  ++ lib.optionals withX11 [
    xorg.libX11
    xorg.xorgproto
  ]
  ++ lib.optionals withWayland [
    waylandpp
    libxkbcommon
  ];

  cmakeFlags = [
    (lib.cmakeBool "USE_INTERNAL_CPPTRACE" false)
    (lib.cmakeFeature "ODAMEX_INSTALL_BINDIR" "$ODAMEX_BINDIR") # set by wrapper
  ];

  installPhase = ''
    runHook preInstall

    ${
      if stdenv.hostPlatform.isDarwin then
        # bash
        ''
          mkdir -p $out/{Applications,bin}

          cp server/odasrv $out/bin
          mv client odamex

          for name in odamex odalaunch; do
            contents="Applications/"$name".app/Contents/MacOS"
            mv $name/*.app $out/Applications
            makeWrapper $out/{"$contents",bin}/"$name" \
              --set ODAMEX_BINDIR "${placeholder "out"}/Applications"
            ln -s "$contents/$name" $out/bin
          done
        ''
      else
        # bash
        ''
          make install

          # copy desktop file icons
          for name in odamex odalaunch odasrv; do
            for size in 96 128 256 512; do
              install -Dm644 ../media/icon_"$name"_"$size".png \
                $out/share/icons/hicolor/"$size"x"$size"/"$name".png
            done
          done
        ''
    }


    runHook postInstall
  '';

  postFixup = lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
    wrapProgram $out/bin/odalaunch \
      --set ODAMEX_BINDIR "${placeholder "out"}/bin"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "odamex";
      icon = "odamex";
      exec = "odamex";
      desktopName = "Odamex Client";
      comment = "A Doom multiplayer game engine";
      categories = [
        "ActionGame"
        "Game"
        "Shooter"
      ];
    })
    (makeDesktopItem {
      name = "odalaunch";
      icon = "odalaunch";
      exec = "odalaunch";
      desktopName = "Odamex Launcher";
      comment = "Server Browser for Odamex";
      categories = [
        "ActionGame"
        "Game"
        "Shooter"
      ];
    })
    (makeDesktopItem {
      name = "odasrv";
      icon = "odasrv";
      exec = "odasrv";
      desktopName = "Odamex Server";
      comment = "Run an Odamex game server";
      categories = [
        "Network"
      ];
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "http://odamex.net/";
    description = "Client/server port for playing old-school Doom online";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ eljamm ];
    mainProgram = "odalaunch";
  };
})
