{
  lib,
  config,
  pkgs,
  ...
}:
let
  this = config.services.taler.libeufin;
  talerEnabled = config.services.taler.enable;
  dbName = "libeufin";
  inherit (config.services.taler) configFile settings;
in
{
  options.services.taler.libeufin = {
    enable = lib.mkEnableOption "GNU Taler libeufin bank";
    package = lib.mkPackageOption pkgs "libeufin" { };
    debug = lib.mkEnableOption "debug logging";
  };

  config = lib.mkIf (talerEnabled && this.enable) {
    services.taler.settings = {
      libeufin-bank = {
        CURRENCY = lib.mkDefault "${settings.taler.CURRENCY}"; # TODO: lower case or upper?
        SERVE = lib.mkDefault "tcp";
        PORT = lib.mkDefault 8082;
        BIND_TO = lib.mkDefault "0.0 0.0"; # TODO: set a HOSTNAME to this as well?
        WIRE_TYPE = lib.mkDefault "x-taler-bank";
        #TODO: check WIRE_TYPE and set X_TALER_BANK_PAYTO_HOSTNAME and IBAN_PAYTO_BIC
        # If WIRE_TYPE = lib.mkDefault x-taler-bank
        X_TALER_BANK_PAYTO_HOSTNAME = lib.mkDefault "http://${settings.libeufin-bank.BIND_TO}:${settings.libeufin-bank.PORT}/";
        #TODO:
        # If WIRE_TYPE = iban
        #IBAN_PAYTO_BIC = lib.mkDefault "SANDBOXX";
        REGISTRATION_BONUS = lib.mkDefault "KUDOS:1000";
        ALLOW_REGISTRATION = lib.mkDefault "yes";
        ALLOW_ACCOUNT_DELETION = lib.mkDefault "yes";
        #TODO: check SSL to determine http or https
        SUGGESTED_WITHDRAWAL_EXCHANGE = lib.mkDefault "https://${settings.exchange.HOSTNAME}:${settings.exchange.port}/";
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
