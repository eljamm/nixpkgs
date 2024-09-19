# WIP: set up common options for Libeufin modules
# NOTE: refactor Taler and Libeufin utils files
{
  lib,
  pkgs,
  config,
  ...
}:
{
  mkLibeufinModule =
    {
      libeufinComponent ? "",
      dbInitScript ? "",
      extraServices ? [ ],
      extraOptions ? { },
      extraConfig ? { },
      ...
    }:
    let
      cfg = cfgMain.${libeufinComponent};
      cfgMain = config.services.libeufin;

      bankServiceName = "libeufin-${libeufinComponent}";
    in
    {
      options = lib.recursiveUpdate {
        services.libeufin.${libeufinComponent} = {
          enable = lib.mkEnableOption "libeufin core banking system and web interface";
          package = lib.mkPackageOption pkgs "libeufin" { };
          debug = lib.mkEnableOption "debug logging";
        };
      } extraOptions;

      config = lib.mkIf cfg.enable (
        lib.recursiveUpdate {
          systemd.services = lib.mergeAttrsList (
            [
              # Main service
              {
                ${bankServiceName} = {
                  serviceConfig = {
                    DynamicUser = true;
                    User = bankServiceName;
                    ExecStart = toString [
                      (lib.getExe' cfg.package "${bankServiceName}")
                      "serve -c ${cfgMain.configFile}"
                      (lib.optionalString cfg.debug " -L debug")
                    ];
                  };
                  requires = [ "${bankServiceName}-dbinit.service" ];
                  after = [ "${bankServiceName}-dbinit.service" ];
                  wantedBy = [ "multi-user.target" ]; # TODO slice?
                };
              }
              # Database Initialisation
              (lib.optionalAttrs (dbInitScript != "") {
                ${bankServiceName} = {
                  path = [ config.services.postgresql.package ];
                  serviceConfig = {
                    Type = "oneshot";
                    DynamicUser = true;
                    User = bankServiceName;
                    ExecStart = toString [
                      (lib.getExe' cfg.package "${bankServiceName}")
                      "dbinit -c ${cfgMain.configFile}"
                      (lib.optionalString cfg.debug " -L debug")
                    ];
                  };
                  requires = [ "postgresql.service" ];
                  after = [ "postgresql.service" ];
                };
              })
            ]
            ++ extraServices
          );

          services = {
            # enable Libeufin when the component is enabled, add settings to the config file
            libeufin = {
              inherit (cfg) enable settings;
            };

            postgresql = {
              enable = true;
              ensureDatabases = [ bankServiceName ];
              ensureUsers = [
                {
                  name = bankServiceName;
                  ensureDBOwnership = true;
                }
              ];
            };
          };
        } extraConfig
      );
    };
}
