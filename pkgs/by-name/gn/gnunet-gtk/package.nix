{
  stdenv,
  fetchurl,
  fetchgit,
  glade,
  gnunet,
  gnutls,
  gtk3,
  libextractor,
  libgcrypt,
  libsodium,
  libxml2,
  pkg-config,
  wrapGAppsHook3,
  meson,
  ninja,
  libtool,
  autoconf,
  automake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gnunet-gtk";
  version = "0.24.3";

  src = fetchgit {
    url = "https://git-www.taler.net/gnunet-gtk.git";
    # tag = "v${finalAttrs.version}";
    rev = "ee1b6f7eca406b1601d67ddab1529fb718653b2a";
    hash = "sha256-t8Zx7Kgtq/9zaQa5FsPfsGKlNRIBfWPVfXShJBThRXE=";
  };

  # strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
    gnutls
    libtool
    autoconf
    automake
    meson
    ninja
  ];

  buildInputs = [
    glade
    gnunet
    gnutls
    gtk3
    libextractor
    libgcrypt
    libsodium
    libxml2
  ];

  configureFlags = [ "--with-gnunet=${finalAttrs.passthru.gnunet}" ];

  # Fix build with GCC14
  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-error=deprecated-declarations"
    "-Wno-error=incompatible-pointer-types"
  ];

  postPatch = "patchShebangs pixmaps/icon-theme-installer";

  # configurePhase = ''
  #   ./bootstrap
  #   ./configure --prefix=${placeholder "out"} "--with-gnunet=${gnunet}"
  # '';
  #
  # buildPhase = ''
  #   make all
  # '';

  postInstall = ''
    ln -s $out/share/gnunet-gtk/gnunet_logo.png $out/share/gnunet/gnunet-logo-color.png
  '';

  passthru = {
    gnunet = gnunet.overrideAttrs (oldAttrs: {
      inherit (finalAttrs) version;
      src = fetchurl {
        url = "mirror://gnu/gnunet/gnunet-${finalAttrs.version}.tar.gz";
        hash = "sha256-WwaJew6ESJu7Q4J47HPkNiRCsuBaY+QAI+wdDMzGxXY=";
      };
    });
  };

  meta = gnunet.meta // {
    description = "GNUnet GTK User Interface";
    homepage = "https://git.gnunet.org/gnunet-gtk.git";
  };
})
