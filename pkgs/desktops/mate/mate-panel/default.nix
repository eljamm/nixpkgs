{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  gettext,
  itstool,
  glib,
  gtk-layer-shell,
  gtk3,
  libmateweather,
  libwnck,
  librsvg,
  libxml2,
  dconf,
  dconf-editor,
  mate-desktop,
  mate-menus,
  hicolor-icon-theme,
  wayland,
  gobject-introspection,
  wrapGAppsHook3,
  marco,
  mateUpdateScript,
}:

stdenv.mkDerivation rec {
  pname = "mate-panel";
  version = "1.28.4";

  src = fetchurl {
    url = "https://pub.mate-desktop.org/releases/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    hash = "sha256-AvCesDFMKsGXtvCJlQpXHNujm/0D1sOguP13JSqWiHQ=";
  };

  nativeBuildInputs = [
    gobject-introspection
    gettext
    itstool
    libxml2 # xmllint
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk-layer-shell
    libmateweather
    libwnck
    librsvg
    dconf
    mate-desktop
    mate-menus
    hicolor-icon-theme
    wayland
  ];

  propagatedBuildInputs = [
    glib
    gtk3
    # Optionally for the ca.desrt.dconf-editor.Settings schema
    # This is propagated for mate_panel_applet_settings_new and applet's wrapGAppsHook3
    dconf-editor
  ];

  # Needed for Wayland support.
  configureFlags = [ "--with-in-process-applets=all" ];

  env.NIX_CFLAGS_COMPILE = "-I${glib.dev}/include/gio-unix-2.0";

  makeFlags = [
    "INTROSPECTION_GIRDIR=$(out)/share/gir-1.0/"
    "INTROSPECTION_TYPELIBDIR=$(out)/lib/girepository-1.0"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      # Workspace switcher settings, works only when passed after gtk3 schemas in the wrapper for some reason
      --prefix XDG_DATA_DIRS : "${glib.getSchemaDataDirPath marco}"
    )
  '';

  enableParallelBuilding = true;

  passthru.updateScript = mateUpdateScript { inherit pname; };

  meta = with lib; {
    description = "MATE panel";
    homepage = "https://github.com/mate-desktop/mate-panel";
    license = with licenses; [
      gpl2Plus
      lgpl2Plus
      fdl11Plus
    ];
    platforms = platforms.unix;
    teams = [ teams.mate ];
  };
}
