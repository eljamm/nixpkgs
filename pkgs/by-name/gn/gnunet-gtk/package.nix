{
  stdenv,
  fetchgit,
  fetchurl,

  # build
  pkg-config,
  wrapGAppsHook3,
  gnutls,
  meson,
  ninja,

  # deps
  glade,
  gnunet,
  gtk3,
  libextractor,
  libgcrypt,
  libsodium,
  libxml2,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gnunet-gtk";
  version = "0.24.3";

  src = fetchgit {
    url = "https://git-www.taler.net/gnunet-gtk.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LvkIdJvJKo5Oa2iuN4TXiFwpO48k3uzVyjoFY9jzY0w=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
    gnutls
    meson
    ninja
  ];

  buildInputs = [
    glade
    finalAttrs.passthru.gnunet
    gnutls
    gtk3
    libextractor
    libgcrypt
    libsodium
    libxml2
  ];

  configureFlags = [ "--with-gnunet=${finalAttrs.passthru.gnunet}" ];

  postPatch = ''
    patchShebangs pixmaps/icon-theme-installer
  '';

  postInstall = ''
    pushd ../pixmaps
      for pixmap in *.{png,svg}; do
          if [ -f "$pixmap" ]; then
              install -D "$pixmap" "$out/share/gnunet-gtk/$pixmap"
          fi
      done
    popd

    pushd $out/share/gnunet-gtk
      ln -s gnunet_logo.png gnunet-logo-color.png
    popd
  '';

  passthru = {
    # `gnunet-gtk` requires approximately the same version as `gnunet`, as the
    # build fails with newer versions
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
