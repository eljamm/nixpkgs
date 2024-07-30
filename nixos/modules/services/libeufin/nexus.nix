{
  lib,
  config,
  options,
  pkgs,
  ...
}:
# TODO: refactor shared code with the bank
let
  this = config.services.libeufin.nexus;
  nexusServiceName = "libeufin-nexus";
  dbinitServiceName = "libeufin-nexus-dbinit";
  inherit (config.services.libeufin) configFile;
in
{
  options.services.libeufin.nexus = {
    enable = lib.mkEnableOption "EBICS facilitator and component of the libeufin core banking system";
    package = lib.mkPackageOption pkgs "libeufin" { };
    debug = lib.mkEnableOption "debug logging";

    settings = lib.mkOption {
      description = ''
        Configuration options for the libeufin nexus config file.

        For a list of all possible options, please see the man page [`libeufin-nexus.conf(5)`](https://docs.taler.net/manpages/libeufin-nexus.conf.5.html)
      '';
      type = lib.types.submodule {
        inherit (options.services.libeufin.settings.type.nestedTypes) freeformType;
        options = {
          nexus-ebics = {
            CURRENCY = lib.mkOption {
              type = lib.types.str;
              default = "${config.services.taler.settings.taler.CURRENCY}";
              defaultText = "{option}`services.taler.settings.taler.CURRENCY`";
              description = ''
                The currency under which the libeufin-nexus should operate.

                This defaults to the GNU taler module's currency for convenience
                but if you run libeufin-bank separately from taler, you must set
                this yourself.
              '';
            };
          };
          nexus-httpd = {
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 8083;
              description = ''
                The port on which libeufin-bank should listen.
              '';
            };
          };
          # TODO: should nexus be in a different DB?
          libeufin-nexusdb-postgres = {
            CONFIG = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "postgresql:///${nexusServiceName}";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf this.enable {
    services.libeufin = {
      inherit (this) enable settings;
    };

    systemd.services =
      let
        nexusExe = "${lib.getExe' this.package nexusServiceName}";
      in
      {
        ${nexusServiceName} = {
          serviceConfig = {
            DynamicUser = true;
            User = nexusServiceName;
            ExecStart = "${nexusExe} serve -c ${configFile}" + lib.optionalString this.debug " -L debug";
          };
          requires = [ "${dbinitServiceName}.service" ];
          after = [ "${dbinitServiceName}.service" ];
          wantedBy = [ "multi-user.target" ]; # TODO slice?
        };
        ${dbinitServiceName} = {
          path = [ config.services.postgresql.package ];
          script = "${nexusExe} dbinit -c ${configFile}" + lib.optionalString this.debug " -L debug";
          serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            User = nexusServiceName;
          };
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };
      };

    services.postgresql.enable = true;
    services.postgresql.ensureDatabases = [ nexusServiceName ];
    services.postgresql.ensureUsers = [
      {
        name = nexusServiceName;
        ensureDBOwnership = true;
      }
    ];
  };
}
