{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vg";
  version = "1.74.0";

  src = fetchFromGitHub {
    owner = "vgteam";
    repo = "vg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-22Q7CZ4GncCaiuJHZk9vUlVf+0Q4Mrf+esD70OLNk3I=";
    fetchSubmodules = true;
  };

  meta = {
    description = "Tools for working with genome variation graphs";
    homepage = "https://github.com/vgteam/vg";
    mainProgram = "vg";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
