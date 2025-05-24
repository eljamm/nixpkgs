{
  lib,
  anki-utils,
  newScope,
  ...
}:
lib.makeScope newScope (
  self:
  let
    callPackage = self.newScope {
      inherit (anki-utils)
        buildAnkiAddon
        buildAnkiAddonsDir
        ;
    };
  in
  {
    adjust-sound-volume = callPackage ./adjust-sound-volume { };

    anki-connect = callPackage ./anki-connect { };

    local-audio-yomichan = callPackage ./local-audio-yomichan { };

    ankimon = callPackage ./ankimon { };

    passfail2 = callPackage ./passfail2 { };

    recolor = callPackage ./recolor { };

    reviewer-refocus-card = callPackage ./reviewer-refocus-card { };

    yomichan-forvo-server = callPackage ./yomichan-forvo-server { };

    review-heatmap = callPackage ./review-heatmap { };
  }
)
