{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
  nix-update-script,
}:
buildAnkiAddon (finalAttrs: {
  pname = "ankimon";
  version = "1.288";

  src = fetchFromGitHub {
    owner = "Unlucky-Life";
    repo = "ankimon";
    rev = finalAttrs.version;
    hash = "sha256-PPTmZpxeBv0zb8wbxLEozDdRJG+eYjMqGyx8y5na1MQ=";
  };

  sourceRoot = "source/src/Ankimon";

  passthru.updateScript = nix-update-script { };

  # Missing, unused and removed in unstable, but prevents the addon from loading.
  # see https://github.com/Unlucky-Life/ankimon/issues/198
  # TODO: remove on next stable release
  postPatch = ''
    substituteInPlace __init__.py \
    --replace-fail "from PyQt6.QtMultimediaWidgets import QVideoWidget" ""
  '';

  meta = {
    description = "Anki Addon to Gamify your learning experience";
    homepage = "https://github.com/Unlucky-Life/ankimon";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ eljamm ];
    broken = true; # TODO: fix
  };
})
