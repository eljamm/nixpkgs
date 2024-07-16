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
    services.taler.settings = {
      libeufin-bank = rec {
        CURRENCY = "KUDOS"; # TODO: lower case or upper?
        SERVE = "tcp";
        PORT = 8082;
        BIND_TO = "libeufin.hephaistos.foo.bar"; # TODO: set a HOSTNAME to this as well?
        WIRE_TYPE = "x-taler-bank";
        #TODO: check WIRE_TYPE and set X_TALER_BANK_PAYTO_HOSTNAME and IBAN_PAYTO_BIC
        # If WIRE_TYPE = x-taler-bank
        X_TALER_BANK_PAYTO_HOSTNAME = "http://${BIND_TO}:${toString PORT}/";
        #TODO:
        # If WIRE_TYPE = iban
        #IBAN_PAYTO_BIC = "SANDBOXX";
        REGISTRATION_BONUS = "${CURRENCY}:100";
        ALLOW_REGISTRATION = "yes";
        ALLOW_ACCOUNT_DELETION = "yes";
        #TODO: check SSL to determine http or https
        SUGGESTED_WITHDRAWAL_EXCHANGE = "https://${talerSettings.exchange.HOSTNAME}:${toString talerSettings.exchange.PORT}/";
      };
      libeufin-bankdb-postgres = {
        CONFIG = "postgresql:///${dbName}";
      };
      libeufin-nexusdb-postgres = {
        CONFIG = "postgresql:///${dbName}";
      };
    };

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
