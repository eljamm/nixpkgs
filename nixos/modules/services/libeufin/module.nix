{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.services.libeufin;
  settingsFormat = pkgs.formats.ini { };
in

{
  options.services.libeufin = {
    enable = lib.mkEnableOption "the libeufin system" // lib.mkOption { internal = true; };
    configFile = lib.mkOption {
      internal = true;
      default = settingsFormat.generate "generated-libeufin.conf" cfg.settings;
    };
    settings = lib.mkOption {
      description = "Global configuration options for the libeufin bank system config file.";
      type = lib.types.submodule { freeformType = settingsFormat.type; };
      default = { };
    };
    stateDir = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "/var/lib/libeufin";
      description = ''
        State directory shared between the taler services.

        The libeufin Nexus stores its client and bank keys here.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."libeufin/libeufin.conf".source = cfg.configFile;
  };
}
