{
  lib,
  stdenv,
  fetchgit,
  curl,
  gnunet,
  jansson,
  libgcrypt,
  libmicrohttpd,
  libsodium,
  libunistring,
  pkg-config,
  libpq,
  autoreconfHook,
  python3,
  recutils,
  wget,
  jq,
  gettext,
  texinfo,
  libtool,

  makeWrapper,
  ghostscript_headless,
  gnumake,
  groff,
  pandoc,
  sphinx,
  which,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "taler-exchange";
  version = "1.0.0";

  src = fetchgit {
    url = "https://git.taler.net/exchange.git";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-75xT9kPCpbk9VBMpqFqXCmPU3PSr22JsCQ//Gi+e7Ds=";
  };

  patches = [ ./0001-add-TALER_TEMPLATING_init_path.patch ];

  nativeBuildInputs = [
    autoreconfHook
    recutils # recfix
    pkg-config
    (python3.withPackages (p: with p; [ jinja2 ]))
    texinfo # makeinfo
    # jq is necessary for some tests and is checked by configure script
    jq
    makeWrapper
  ];

  buildInputs = [
    libgcrypt
    libmicrohttpd
    jansson
    libsodium
    libpq
    libtool
    curl
    gettext
    libunistring
  ];

  strictDeps = true;

  propagatedBuildInputs = [ gnunet ];

  # From ./bootstrap
  preAutoreconf = ''
    ./contrib/gana-generate.sh
    pushd contrib
    rm -f Makefile.am
    {
      echo 'dist_amlspapkgdata_DATA = \'
      find wallet-core/aml-backoffice/ -type f | sort | awk '{print "  " $1 " \\" }'
    }  >> Makefile.am.ext
    # Remove extra '\' at the end of the file
    truncate -s -2 Makefile.am.ext

    {
      echo ""
      echo 'dist_kycspapkgdata_DATA = \'
      find wallet-core/kyc/ -type f | sort | awk '{print "  " $1 " \\" }'
    }  >> Makefile.am.ext
    # Remove extra '\' at the end of the file
    truncate -s -2 Makefile.am.ext

    {
      echo ""
      echo 'dist_auditorspapkgdata_DATA = \'
      find wallet-core/auditor-backoffice/ -type f | sort | awk '{print "  " $1 " \\" }'
    }  >> Makefile.am.ext
    # Remove extra '\' at the end of the file
    truncate -s -2 Makefile.am.ext

    cat Makefile.am.in Makefile.am.ext >> Makefile.am
    # Prevent accidental editing of the generated Makefile.am
    chmod -w Makefile.am
    popd
  '';

  configureFlags = [
    "ac_cv_path__libcurl_config=${lib.getDev curl}/bin/curl-config"
  ];

  postPatch = ''
    # Can only `return` from a function or sourced script
    for file in taler-exchange-kyc-oauth2-{challenger,nda}.sh; do
      substituteInPlace src/kyclogic/$file \
        --replace-fail "return 1" "exit 1"
    done
  '';

  postFixup = ''
    # Wrap scripts with necessary runtime dependencies
    for file in \
      taler-exchange-helper-measure-test-{form,oauth} \
      taler-exchange-helper-converter-oauth2-test-full_name \
      taler-exchange-kyc-aml-pep-trigger.sh \
      taler-exchange-kyc-kycaid-converter.sh \
      taler-exchange-kyc-oauth2-{challenger,nda,test-converter}.sh \
      taler-exchange-kyc-persona-converter.sh \
      ; do
        wrapProgram $out/bin/$file \
          --prefix PATH : ${
            lib.makeBinPath [
              gnunet
              jq
              wget
              which
            ]
          }
    done
    # Put scripts with big dependency closures in separate outputs
    mkdir -p $terms/bin
    mv $out/bin/taler-terms-generator $terms/bin/taler-terms-generator
    wrapProgram $terms/bin/taler-terms-generator \
      --prefix PATH : ${
        lib.makeBinPath [
          ghostscript_headless
          gnumake
          groff
          pandoc
          sphinx
          which
          (python3.withPackages (p: with p; [ sphinx-markdown-builder ]))
          (placeholder "out")
        ]
      }
    # This script imperatively sets up Taler components for testing, which not
    # only needs a considerable amount of dependencies, but is also better
    # handled by Taler's NixOS module.
    rm $out/bin/taler-unified-setup.sh
  '';

  outputs = [
    "out"
    "terms"
  ];

  enableParallelBuilding = true;

  doInstallCheck = true;

  nativeCheckInputs = [
    wget
    curl
  ];

  checkTarget = "check";

  meta = {
    description = "Exchange component for the GNU Taler electronic payment system";
    longDescription = ''
      Taler is an electronic payment system providing the ability to pay
      anonymously using digital cash.  Taler consists of a network protocol
      definition (using a RESTful API over HTTP), an Exchange (which creates
      digital coins), a Wallet (which allows customers to manage, store and
      spend digital coins), and a Merchant website which allows customers to
      spend their digital coins.  Naturally, each Merchant is different, but
      Taler includes code examples to help Merchants integrate Taler as a
      payment system.
    '';
    homepage = "https://taler.net/";
    changelog = "https://git.taler.net/exchange.git/tree/ChangeLog";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ astro ];
    platforms = lib.platforms.linux;
  };
})
