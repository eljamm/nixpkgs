{
  lib,
  stdenv,
  esbuild,
  buildGoModule,
  fetchFromGitHub,
  fetchgit,
  nodejs_20,
  pnpm_9,
  python3,
  gitMinimal,
  jq,
  zip,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "taler-wallet-core";
  version = "1.2.2";

  src = fetchgit {
    url = "https://git-www.taler.net/taler-typescript-core.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3Qx3L+MjKP7HeNztsGUYAN9UF09PxeswMLarlaHeb4I=";
  };

  patches = [
    ./0001-fix-add-missing-directDepositsDisabled.patch
  ];

  nativeBuildInputs = [
    finalAttrs.passthru.python
    nodejs_20
    pnpm_9.configHook
    gitMinimal
    jq
    zip
  ];

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-jwoSvqE0hqRxu76vDtUOpZxvi4SsmKukfpmp5G6ZV/I=";
  };

  buildInputs = [ nodejs_20 ];

  postPatch = ''
    patchShebangs packages/*/*.mjs

    # don't fetch submodules
    substituteInPlace bootstrap \
      --replace-fail "! git --version >/dev/null" "false" \
      --replace-fail "git" "#git"

    substituteInPlace pnpm-lock.yaml \
      --replace-fail \
        "esbuild: 0.12.29" \
        "esbuild: ${finalAttrs.passthru.esbuild'.version}"
  '';

  preConfigure = ''
    ./bootstrap
  '';

  postFixup = ''
    # else it fails to find the python interpreter
    patchShebangs --build $out/bin/taler-helper-sqlite3
  '';

  env.ESBUILD_BINARY_PATH = lib.getExe finalAttrs.passthru.esbuild';

  passthru = {
    python = python3.withPackages (p: [ p.setuptools ]);
    esbuild' = esbuild.override {
      buildGoModule =
        args:
        buildGoModule (
          args
          // rec {
            version = "0.19.9";
            src = fetchFromGitHub {
              owner = "evanw";
              repo = "esbuild";
              rev = "v${version}";
              hash = "sha256-GiQTB/P+7uVGZfUaeM7S/5lGvfHlTl/cFt7XbNfE0qw=";
            };
            vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
          }
        );
    };
  };

  meta = {
    homepage = "https://git.taler.net/wallet-core.git/";
    description = "CLI wallet for GNU Taler written in TypeScript and Anastasis Web UI";
    license = lib.licenses.gpl3Plus;
    teams = [ lib.teams.ngi ];
    platforms = lib.platforms.linux;
    mainProgram = "taler-wallet-cli";
    # ./configure doesn't understand --build / --host
    broken = stdenv.buildPlatform != stdenv.hostPlatform;
  };
})
