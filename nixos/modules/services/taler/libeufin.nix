{
  lib,
  config,
  pkgs,
  ...
}:
let
  this = config.services.taler.libeufin;
  talerEnabled = config.services.taler.enable;
  talerSettings = config.services.taler.settings;
  dbName = "libeufin";
  inherit (config.services.taler) configFile;
in
{
  options.services.taler.libeufin = {
    enable = lib.mkEnableOption "GNU Taler libeufin bank";
    package = lib.mkPackageOption pkgs "libeufin" { };
    debug = lib.mkEnableOption "debug logging";
  };

  config = lib.mkIf (talerEnabled && this.enable) {
    systemd.services = {
      libeufin-dbinit = {
        path = [ config.services.postgresql.package ];
        script =
          "${this.package}/bin/libeufin-bank-dbinit -c ${configFile}"
          + lib.optionalString this.debug " -L debug";
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          User = "libeufin";
        };
      };
    };

    services.postgresql.enable = true;
    services.postgresql.ensureDatabases = [ dbName ];
    #TODO: what services need DB access?
    services.postgresql.ensureUsers = [
      {
        name = "${dbName}";
        ensureDBOwnership = true; # TODO clean this up
      }
    ];
  };
}
