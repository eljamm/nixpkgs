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

      bankServiceName = "libeufin-${libeufinComponent}";

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
                "libeufin-${libeufinComponent}" = {
                  serviceConfig = {
                    DynamicUser = true;
                    User = bankServiceName;
                    ExecStart = toString [
                      (lib.getExe' cfg.package "${bankServiceName}")
                      "serve -c ${cfgMain.configFile}"
                      (lib.optionalString cfg.debug " -L debug")
                    ];
                    StateDirectory = lib.mkIf (libeufinComponent == "nexus") bankServiceName;
                    ReadWritePaths = lib.mkIf (libeufinComponent == "nexus") [ "/var/lib/${bankServiceName}" ];
                  };
                  requires = [ "${bankServiceName}-dbinit.service" ];
                  after = [ "${bankServiceName}-dbinit.service" ];
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
                "libeufin-${libeufinComponent}-dbinit" = {
                  path = [ config.services.postgresql.package ];
                  serviceConfig = {
                    Type = "oneshot";
                    DynamicUser = true;
                    User = bankServiceName;
                    ExecStart = toString [
                      (lib.getExe' cfg.package "libeufin-${libeufinComponent}")
                      "dbinit -c ${cfgMain.configFile}"
                      (lib.optionalString cfg.debug " -L debug")
                    ];
                  };
                  requires = [ "postgresql.service" ];
                  after = [ "postgresql.service" ];
                };
              }
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
