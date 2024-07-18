{
  lib,
  config,
  pkgs,
  ...
}:
let
  this = config.services.taler.libeufin.bank;
  talerEnabled = config.services.taler.enable;
  bankServiceName = "libeufin-bank";
  inherit (config.services.taler) configFile;
in
{
  options.services.taler.libeufin.bank = {
    enable = lib.mkEnableOption "GNU Taler libeufin bank";
    package = lib.mkPackageOption pkgs "libeufin" { };
    debug = lib.mkEnableOption "debug logging";
    # TODO admin password option
  };

  config = lib.mkIf (talerEnabled && this.enable) {
    systemd.services = {
      ${bankServiceName} = {
        script =
          "${lib.getExe this.package} serve -c ${configFile}"
          + lib.optionalString this.debug " -L debug";
        serviceConfig = {
          DynamicUser = true;
          User = bankServiceName;
        };
        requires = [ "libeufin-dbinit.service" ];
        after = [ "libeufin-dbinit.service" ];
        wantedBy = [ "multi-user.target" ]; # TODO slice?
      };
      libeufin-dbinit = {
        path = [ config.services.postgresql.package ];
        script =
          "${lib.getExe this.package} dbinit -c ${configFile}"
          + lib.optionalString this.debug " -L debug";
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          User = bankServiceName;
        };
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
      };
    };

    services.taler.settings.libeufin-bankdb-postgres.CONFIG = "postgresql:///${bankServiceName}";

    services.postgresql.enable = true;
    services.postgresql.ensureDatabases = [ bankServiceName ];
    services.postgresql.ensureUsers = [
      {
        name = bankServiceName;
        ensureDBOwnership = true;
      }
    ];
  };
}
