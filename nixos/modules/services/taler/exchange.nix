{
  lib,
  config,
  options,
  pkgs,
  ...
}:

let
  this = config.services.taler.exchange;
  # Services that need access to the DB
  # https://docs.taler.net/taler-exchange-manual.html#services-users-groups-and-file-system-hierarchy
  servicesDB = [
    "httpd"
    "aggregator"
    "closer"
    "wirewatch"
  ];
  # Services that do not need access to the DB
  servicesNoDB = [
    "secmod-cs"
    "secmod-eddsa"
    "secmod-rsa"
  ];
  services = servicesDB ++ servicesNoDB;
  dbName = "taler-exchange-httpd";
  groupName = "taler-exchange-services";
  # taler-exchange needs a runtime dir shared between the taler services. Crypto
  # helpers put their sockets here for instance and the httpd connects to them.
  runtimeDir = "/run/taler-system-runtime/";
  inherit (config.services.taler) configFile;
in

{
  options.services.taler.exchange = {
    enable = lib.mkEnableOption "the GNU Taler exchange";
    package = lib.mkPackageOption pkgs "taler-exchange" { };
    denominationConfig = lib.mkOption {
      type = lib.types.lines;
      # TODO how to boostrap?
      default = throw "You must set the denomination config `services.taler.exchange.denominationConfig`.";
      defaultText = "None, you must set this yourself.";
      example = ''
        [COIN-KUDOS-n1-t1718140083]
        VALUE = KUDOS:0.1
        DURATION_WITHDRAW = 7 days
        DURATION_SPEND = 2 years
        DURATION_LEGAL = 6 years
        FEE_WITHDRAW = KUDOS:0
        FEE_DEPOSIT = KUDOS:0.1
        FEE_REFRESH = KUDOS:0
        FEE_REFUND = KUDOS:0
        RSA_KEYSIZE = 2048
        CIPHER = RSA
      '';
      # TODO why does the wallet not have a deployment subcommand when it should?
      description = ''
        This option configures the cash denomination for the coins that the exchange offers.
        For more information, consult the docs: https://docs.taler.net/taler-exchange-manual.html#coins-denomination-keys

        You can either write these manually or you can use the `taler-harness deployment gen-coin-config`
        command to generate it.

        Warning: Do not modify existing denominations after deployment.
        Please see the upstream docs for how to safely do that.
      '';
    };
    debug = lib.mkEnableOption "debug logging";
    settings = lib.mkOption {
      type = lib.types.submodule {
        inherit (options.services.taler.settings.type.nestedTypes) freeformType;
        options = {
          # TODO do we want this to be a sub-attribute or only define the exchange set of options here
          exchange = {
            AML_THRESHOLD = lib.mkOption {
              type = lib.types.str;
              default = "${config.services.taler.settings.taler.CURRENCY}:1000000";
              defaultText = "1000000 in {option}`CURRENCY`";
            };
            DB = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "postgres";
            };
            MASTER_PUBLIC_KEY = lib.mkOption {
              type = lib.types.str;
              default = throw ''
                You must provide `MASTER_PUBLIC_KEY` with the public part of your master key.

                This will be used by the auditor service to get information about the exchange.
                For more information, see https://docs.taler.net/taler-auditor-manual.html#initial-configuration

                To generate this key, you must run `taler-exchange-offline setup`. It will print the public key.
              '';
              defaultText = "None, you must set this yourself.";
            };
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 8081;
            };
          };
          exchangedb-postgres = {
            CONFIG = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "postgres:///${dbName}";
            };
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf this.enable {
    services.taler = {
      inherit (this) enable settings;
      includes = [ (pkgs.writers.writeText "exchange-denominations.conf" this.denominationConfig) ];
    };

    systemd.slices.taler-exchange = {
      description = "Slice for GNU taler exchange processes";
      before = [ "slices.target" ];
    };

    systemd.services =
      lib.genAttrs (map (n: "taler-exchange-${n}") services) (name: {
        serviceConfig = {
          DynamicUser = true;
          User = name;
          Group = groupName;
          ExecStart =
            "${this.package}/bin/${name} -c ${configFile}" + lib.optionalString this.debug " -L debug";
          RuntimeDirectory = name;
          StateDirectory = name;
          CacheDirectory = name;
          ReadWritePaths = [ runtimeDir ];
          # TODO more hardening
          # PrivateTmp = "yes";
          # PrivateDevices = "yes";
          # ProtectSystem = "full";
          # Slice = "taler-exchange.slice";
        };
        requires = [ "taler-exchange-dbinit.service" ];
        after = [ "taler-exchange-dbinit.service" ];
        wantedBy = [ "multi-user.target" ]; # TODO slice?
      })
      // {
        taler-exchange-dbinit = {
          path = [ config.services.postgresql.package ];
          script =
            let
              # Taken from https://docs.taler.net/taler-exchange-manual.html#exchange-database-setup
              # TODO Why does aggregator need DELETE?
              dbScript = pkgs.writers.writeText "taler-exchange-db-permissions.sql" ''
                GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA exchange TO "taler-exchange-aggregator";
                GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA exchange TO "taler-exchange-closer";
                GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA exchange TO "taler-exchange-wirewatch";
                GRANT USAGE ON SCHEMA exchange TO "taler-exchange-aggregator";
                GRANT USAGE ON SCHEMA exchange TO "taler-exchange-closer";
                GRANT USAGE ON SCHEMA exchange TO "taler-exchange-wirewatch";
              '';
            in
            ''
              ${this.package}/bin/taler-exchange-dbinit

              psql -f ${dbScript}
            '';
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
          serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            User = dbName;
          };
        };
      };

    users.groups.${groupName} = { };

    systemd.tmpfiles.settings = {
      "10-taler-exchange" = {
        "${runtimeDir}" = {
          d = {
            group = groupName;
            user = "nobody";
            mode = "070";
          };
        };
      };
    };
    services.postgresql.enable = true;
    services.postgresql.ensureDatabases = [ dbName ];
    services.postgresql.ensureUsers =
      map (service: { name = "taler-exchange-${service}"; }) servicesDB
      ++ [
        {
          name = dbName;
          ensureDBOwnership = true;
        }
      ];
  };
}
