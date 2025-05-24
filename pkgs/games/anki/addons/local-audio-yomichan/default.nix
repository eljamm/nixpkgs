{
  lib,
  buildAnkiAddon,
  fetchFromGitHub,
  python3,
  nix-update-script,
}:
buildAnkiAddon {
  pname = "local-audio-yomichan";
  version = "0-unstable-2025-04-26";

  src = fetchFromGitHub {
    owner = "yomidevs";
    repo = "local-audio-yomichan";
    rev = "34750f1d8ca1cb473128fea7976a4d981e5e78a4";
    sparseCheckout = [ "plugin" ];
    hash = "sha256-2gyggcvxParay+1B7Sg2COKyocoxaRO1WTz+ymdRp4w=";
  };

  sourceRoot = "source/plugin";

  processUserFiles = ''
    # Addon will try to load extra stuff unless Python package name is "plugin".
    temp=$(mktemp -d)
    ln -s $PWD $temp/plugin
    # Addoon expects `user_files` dir at `$XDG_DATA_HOME/local-audio-yomichan`
    ln -s $PWD/user_files $temp/local-audio-yomichan

    PYTHONPATH=$temp \
    WO_ANKI=1 \
    XDG_DATA_HOME=$temp \
    ${lib.getExe python3} -c \
      "from plugin import db_utils; \
       db_utils.init_db()"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta = {
    description = "Anki add-on to run a local audio server for Yomitan";
    homepage = "https://github.com/yomidevs/local-audio-yomichan";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ junestepp ];
  };
}
