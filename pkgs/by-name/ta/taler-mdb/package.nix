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
  libnfc,
  libsodium,
  qrencode,
  taler-exchange,
  taler-merchant,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "taler-mdb";
  version = "1.1.0";

  src = fetchgit {
    url = "https://git-www.taler.net/taler-mdb.git";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-44dzusDkWHtjZybwYG7Ttp7NpGSW1ftsN9rDTDdS504=";
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
    libnfc
    libsodium
    qrencode
    taler-exchange
    taler-merchant
  ];

  doCheck = true;

  meta = {
    homepage = "https://git.taler.net/taler-mdb.git";
    description = "Sales integration with the Multi-Drop-Bus of Snack machines, NFC readers and QR code display";
    license = lib.licenses.agpl3Plus;
    teams = with lib.teams; [ ngi ];
    maintainers = [ ];
    mainProgram = "taler-mdb";
  };
})
