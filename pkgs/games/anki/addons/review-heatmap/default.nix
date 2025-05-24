{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
  python3Packages,
  gitMinimal,
}:

let
  pname = "review-heatmap";
  version = "1.0.1";

  review-heatmap = python3Packages.buildPythonApplication {
    inherit pname version;
    format = "other";

    # FIX: where is src/web/anki-review-heatmap.js?
    src = fetchFromGitHub {
      owner = "glutanimate";
      repo = "review-heatmap";
      rev = "v${version}";
      hash = "sha256-KQaCj9xdKM3Uv+JnYTmkxFbMevhmqugyBkPX4+QsZSY=";
      leaveDotGit = true;
    };

    build-system = with python3Packages; [
      pyqt6
      aab
    ];

    nativeBuildInputs = [
      gitMinimal
    ];

    buildPhase = ''
      runHook preBuild

      # work around missing files
      mkdir resources/icons/optional
      for file in patreon thanks twitter youtube; do
        cp resources/icons/email.svg resources/icons/optional/$file.svg
      done

      aab build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      cp -R build/* $out

      runHook postInstall
    '';
  };
in

buildAnkiAddon (finalAttrs: {
  inherit pname version;
  src = review-heatmap;

  sourceRoot = "${finalAttrs.src.name}/dist/src/review_heatmap";

  meta = {
    description = "Anki add-on to help you keep track of your review activity";
    homepage = "https://github.com/glutanimate/review-heatmap";
    changelog = "https://github.com/glutanimate/review-heatmap/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ eljamm ];
    broken = true; # TODO: fix, missing anki-review-heatmap.js file
  };
})
