{
  stdenv,
  lib,
  fetchFromGitHub,
  desktop-file-utils,
  meson,
  ninja,
  pkg-config,
  vala,
  wrapGAppsHook4,
  evolution-data-server-gtk4,
  glib,
  glib-networking,
  gst_all_1,
  gtk4,
  gtksourceview5,
  gxml,
  json-glib,
  libadwaita,
  libgee,
  libical,
  libportal-gtk4,
  libsecret,
  libsoup_3,
  pantheon,
  sqlite,
  webkitgtk_6_0,
}:

stdenv.mkDerivation rec {
  pname = "planify";
  version = "4.13.0";

  src = fetchFromGitHub {
    owner = "alainm23";
    repo = "planify";
    rev = version;
    hash = "sha256-4fsgXyIt5bhdbG0DRFYv6vrGagTyH5SAFcOaAV3uq0g=";
  };

  nativeBuildInputs = [
    desktop-file-utils
    meson
    ninja
    pkg-config
    vala
    wrapGAppsHook4
  ];

  buildInputs = [
    evolution-data-server-gtk4
    glib
    glib-networking
    # Needed for GtkMediaStream creation with success.ogg, see #311295.
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gtk4
    gtksourceview5
    gxml
    json-glib
    libadwaita
    libgee
    libical
    libportal-gtk4
    libsecret
    libsoup_3
    pantheon.granite7
    sqlite
    webkitgtk_6_0
  ];

  meta = with lib; {
    description = "Task manager with Todoist support designed for GNU/Linux";
    homepage = "https://github.com/alainm23/planify";
    license = licenses.gpl3Plus;
    teams = [ teams.pantheon ];
    platforms = platforms.linux;
    mainProgram = "io.github.alainm23.planify";
  };
}
