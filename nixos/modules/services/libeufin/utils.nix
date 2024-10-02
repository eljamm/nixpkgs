# TODO: create a common module generator for Taler and Libeufin?
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
      extraServices ? [ ],
      extraOptions ? { },
      extraConfig ? { },
      ...
    }:
    let
      cfg = cfgMain.${libeufinComponent};
      cfgMain = config.services.libeufin;

      servicesGroup = "libeufin-services";
      serviceName = "libeufin-${libeufinComponent}";

      # TODO: enforce that bank and nexus be in the same db?
      dbName =
        lib.removePrefix "postgresql:///"
          cfg.settings."libeufin-${libeufinComponent}db-postgres".CONFIG;

      inherit (cfgMain) stateDir;
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
                "${serviceName}" = {
                  serviceConfig = {
                    DynamicUser = true;
                    User = serviceName;
                    Group = servicesGroup;
                    SupplementaryGroups = [ servicesGroup ];
                    ExecStart = toString [
                      (lib.getExe' cfg.package "libeufin-${libeufinComponent}")
                      "serve -c ${cfgMain.configFile}"
                      (lib.optionalString cfg.debug " -L debug")
                    ];
                  };
                  requires = [ "libeufin-nexus-dbinit.service" ];
                  after = [ "libeufin-nexus-dbinit.service" ];
                  wantedBy = [ "multi-user.target" ]; # TODO slice?
                  # Accounts to enable before the bank service starts.
                  preStart =
                    let
                      registerAccounts = lib.pipe cfg.initialAccounts [
                        (map (account: ''
                          ${lib.getExe' cfg.package "libeufin-bank"} create-account \
                              -c ${cfgMain.configFile} \
                              --username ${account.username} \
                              --password ${account.password} \
                              --name ${account.name} \
                              --payto_uri="payto://x-taler-bank/bank:8082/${account.username}?receiver-name=${account.name}" \
                              ${lib.optionalString (lib.toLower account.username == "exchange") "--exchange"}
                        ''))
                        (lib.concatStringsSep "\n")
                      ];
                    in
                    lib.mkIf (libeufinComponent == "bank") ''
                      if [ ! -e ${stateDir}/init ]; then
                        ${registerAccounts}
                      fi
                    '';
                };
              }
              # Database Initialisation
              {
                "${serviceName}-dbinit" =
                  let
                    # NOTE: the bank also needs this for currency conversion
                    dbScript = pkgs.writers.writeText "libeufin-nexus-db-permissions.sql" ''
                      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA libeufin_nexus TO "${serviceName}";
                      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA libeufin_bank TO "${serviceName}";
                      GRANT USAGE ON SCHEMA libeufin_nexus TO "${serviceName}";
                      GRANT USAGE ON SCHEMA libeufin_bank TO "${serviceName}";
                    '';
                    # NOTE: the bank and nexus shouldn't initialise the database at the same time
                    serviceReq =
                      if (libeufinComponent == "nexus") then
                        [ "libeufin-bank-dbinit.service" ]
                      else
                        [ "postgresql.service" ];
                  in
                  {
                    path = [ config.services.postgresql.package ];
                    script = ''
                      ${lib.getExe' cfg.package "libeufin-${libeufinComponent}"} dbinit \
                        -c ${cfgMain.configFile} \
                        ${lib.optionalString cfg.debug "-L debug"}

                      psql -f ${dbScript}
                    '';
                    serviceConfig = {
                      Type = "oneshot";
                      DynamicUser = true;
                      User = dbName;
                    };
                    requires = serviceReq;
                    after = serviceReq;
                  };
              }
            ]
            ++ extraServices
          );

          users.groups.${servicesGroup} = { };

          systemd.tmpfiles.settings = {
            "10-libeufin-services" = {
              "${stateDir}" = {
                d = {
                  group = servicesGroup;
                  user = "nobody";
                  mode = "070";
                };
              };
            };
          };

          services = {
            # enable Libeufin when the component is enabled, add settings to the config file
            libeufin = {
              inherit (cfg) enable settings;
            };

            postgresql = {
              enable = true;
              ensureDatabases = [ dbName ];
              ensureUsers = [
                { name = serviceName; }
                {
                  name = dbName;
                  ensureDBOwnership = true;
                }
              ];
            };
          };
        } extraConfig
      );
    };
}
