{
  lib,
  stdenv,
  fetchgit,
  autoreconfHook,
  libgcrypt,
  pkg-config,
  curlWithGnuTls,
  gnunet,
  jansson,
  libmicrohttpd,
  libpq,
  libsodium,
  libtool,
  taler-exchange,
  taler-merchant,
  runtimeShell,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "taler-sync";
  version = "1.1.0-unstable-2025-10-30";

  src = fetchgit {
    url = "https://git-www.taler.net/sync.git";
    rev = "f541f64392bc18ea13934c6d7b93426ea42bf0a2";
    hash = "sha256-Io0pMceV0+U/GFxkqis0SN4HU8UqlclNBs6G/y9VoQs=";
    # Update submodules to use `git-www.taler.net` since `git.taler.net` no
    # longer hosts source code.
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = ''
      pushd $out
        git reset --hard HEAD
        substituteInPlace .gitmodules \
          --replace-fail "git.taler.net" "git-www.taler.net"
        git submodule update --init --recursive
        rm -rf .git
      popd
    '';
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    libgcrypt
    pkg-config
  ];

  buildInputs = [
    curlWithGnuTls
    gnunet
    jansson
    libgcrypt
    libmicrohttpd
    libpq
    libsodium
    libtool
    taler-exchange
    taler-merchant
  ];

  preFixup = ''
    substituteInPlace "$out/bin/sync-dbconfig" \
      --replace-fail "/bin/bash" "${runtimeShell}"
  '';

  meta = {
    description = "Backup and synchronization service";
    homepage = "https://git.taler.net/sync.git";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ wegank ];
    teams = with lib.teams; [ ngi ];
    platforms = lib.platforms.linux;
  };
})
