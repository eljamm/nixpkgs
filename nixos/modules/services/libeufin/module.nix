{
  lib,
  pkgs,
  config,
  ...
}:

let
  settingsFormat = pkgs.formats.ini { };
  this = config.services.libeufin;
in

{
  options.services.libeufin = {
    enable = lib.mkEnableOption "the libeufin system" // lib.mkOption {
      internal = true;
    };
    configFile = lib.mkOption {
      internal = true;
      default = settingsFormat.generate "generated-taler.conf" this.settings;
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      default = { };
    };
  };

  config = lib.mkIf (this.enable) {
    environment.etc."libeufin/libeufin.conf".source = this.configFile;
  };
}
