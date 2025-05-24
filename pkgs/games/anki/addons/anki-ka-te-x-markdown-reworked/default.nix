{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
}:

buildAnkiAddon (finalAttrs: {
  pname = "anki-ka-te-x-markdown-reworked";
  version = "30";

  src = fetchFromGitHub {
    owner = "alexthillen";
    repo = "Anki-KaTeX-Markdown-Reworked";
    rev = "release/${finalAttrs.version}";
    hash = "sha256-FHBdCSYJJop946PalZKJsXXNYgr9/k+hgJR6PiizisA=";
  };

  sourceRoot = "source/MDKaTeX";

  meta = {
    description = "Creates new Basic and Cloze note types that support Markdown and KaTeX";
    homepage = "https://github.com/alexthillen/Anki-KaTeX-Markdown-Reworked";
    license = lib.licenses.unfree; # FIXME: nix-init did not find a license
    maintainers = with lib.maintainers; [ eljamm ];
  };
})
