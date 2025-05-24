{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
}:
buildAnkiAddon (finalAttrs: {
  pname = "flexible-grading";
  version = "24.11.22.0";

  src =
    (fetchFromGitHub {
      owner = "Ajatt-Tools";
      repo = "FlexibleGrading";
      rev = "v${finalAttrs.version}";
      hash = "sha256-+uzD56AM4i996HeJQKrB63exYyTqRz/ycU1GuzMUtPE=";
      fetchSubmodules = true;
    }).overrideAttrs
      (_: {
        GIT_CONFIG_COUNT = 1;
        GIT_CONFIG_KEY_0 = "url.https://github.com/.insteadOf";
        GIT_CONFIG_VALUE_0 = "git@github.com:";
      });

  sourceRoot = "source";

  meta = {
    description = "Bring keyboard-driven reviewing to Anki";
    homepage = "https://github.com/Ajatt-Tools/FlexibleGrading";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
