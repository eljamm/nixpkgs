{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
}:

buildAnkiAddon (finalAttrs: {
  pname = "minimize-to-tray";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "simgunz";
    repo = "anki21-addons_minimize-to-tray";
    rev = finalAttrs.version;
    hash = "sha256-FWapUZVKI9ojGY6AYTyrEpHz7sP5hxeKyM89Oo8Y0R0=";
  };

  sourceRoot = "source/src";

  meta = {
    description = "Anki add-on that adds an icon to the system tray in order to allow minimizing Anki";
    homepage = "https://github.com/simgunz/anki21-addons_minimize-to-tray";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
