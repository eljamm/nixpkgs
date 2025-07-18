{
  lib,
  autoreconfHook,
  fetchFromGitHub,
  gettext,
  glib,
  gobject-introspection,
  intltool,
  libnotify,
  python3,
  wrapGAppsHook3,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "mpDris2";
  version = "0.9.1";
  format = "other";

  src = fetchFromGitHub {
    owner = "eonpatapon";
    repo = "mpDris2";
    rev = version;
    sha256 = "sha256-1Y6K3z8afUXeKhZzeiaEF3yqU0Ef7qdAj9vAkRlD2p8=";
  };

  preConfigure = ''
    intltoolize -f
  '';

  nativeBuildInputs = [
    autoreconfHook
    gettext
    gobject-introspection
    intltool
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    libnotify
  ];

  propagatedBuildInputs = with python3.pkgs; [
    dbus-python
    mpd2
    mutagen
    pygobject3
  ];

  patches = [ ./fix-gettext-0.25.patch ];

  meta = with lib; {
    description = "MPRIS 2 support for mpd";
    homepage = "https://github.com/eonpatapon/mpDris2/";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "mpDris2";
  };
}
