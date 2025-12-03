{
  lib,
  stdenv,
  fetchgit,
  autoreconfHook,
  pkg-config,
  curl,
  gnunet,
  jansson,
  libgcrypt,
  libmicrohttpd,
  libsodium,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "taler-twister";
  version = "1.1.0";

  src = fetchgit {
    url = "https://git-www.taler.net/twister.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XZ8/e9hdDBp1JEPWsi90Zu41PPN4uqul67/kjyBwszI=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    curl
    gnunet
    jansson
    libgcrypt
    libmicrohttpd
    libsodium
  ];

  doInstallCheck = true;

  meta = {
    homepage = "https://git.taler.net/twister.git";
    description = "Fault injector for HTTP traffic";
    teams = with lib.teams; [ ngi ];
    maintainers = [ ];
    license = lib.licenses.agpl3Plus;
    mainProgram = "twister";
    platforms = lib.platforms.linux;
  };
})
