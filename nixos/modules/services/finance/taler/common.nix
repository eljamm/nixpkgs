# TODO: create a common module generator for Taler and Libeufin?
{
  talerComponent ? "",
  servicesDB ? [ ],
  servicesNoDB ? [ ],
  ...
}:
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = cfgTaler.${talerComponent};
  cfgTaler = config.services.taler;

  settingsFormat = pkgs.formats.ini { };

  configFile = config.environment.etc."taler/taler.conf".source;
  componentConfigFile = settingsFormat.generate "generated-taler-${talerComponent}.conf" cfg.settings;

  services = servicesDB ++ servicesNoDB;

  dbName = "taler-${talerComponent}-httpd";
  groupName = "taler-${talerComponent}-services";

  inherit (cfgTaler) runtimeDir;
in
{
  options = {
    services.taler.${talerComponent} = {
      enable = lib.mkEnableOption "the GNU Taler ${talerComponent}";
      package = lib.mkPackageOption pkgs "taler-${talerComponent}" { };
      # TODO: make option accept multiple debugging levels?
      debug = lib.mkEnableOption "debug logging";
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open ports in the firewall";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.taler.enable = cfg.enable;
    services.taler.includes = [ componentConfigFile ];

    systemd.services = lib.mergeAttrsList [
      # Main services
      (lib.genAttrs (map (n: "taler-${talerComponent}-${n}") services) (name: {
        serviceConfig = {
          DynamicUser = true;
          User = name;
          Group = groupName;
          ExecStart = toString [
            (lib.getExe' cfg.package name)
            "-c ${configFile}"
            (lib.optionalString cfg.debug " -L debug")
          ];
          RuntimeDirectory = name;
          StateDirectory = name;
          CacheDirectory = name;
          ReadWritePaths = [ runtimeDir ];
        };
        requires = [
          "taler-${talerComponent}-dbinit.service"
        ];
        after = [
          "taler-${talerComponent}-dbinit.service"
        ];
        wantedBy = [ "multi-user.target" ]; # TODO slice?
        documentation = [
          "man:taler-${talerComponent}-${name}(1)"
          "info:taler-${talerComponent}"
        ];
        # path = [
        #   config.services.postgresql.package
        #   pkgs.rsync
        # ];
        # preStart =
        #   let
        #     deletePerm = name: lib.optionalString (name == "aggregator") ",DELETE";
        #     dbScript = pkgs.writers.writeText "taler-exchange-db-permissions.sql" (
        #       lib.pipe servicesDB [
        #         (map (name: ''
        #           GRANT SELECT,INSERT,UPDATE${deletePerm name} ON ALL TABLES IN SCHEMA exchange TO "taler-exchange-${name}";
        #           GRANT USAGE ON ALL SEQUENCES IN SCHEMA exchange TO "taler-exchange-${name}";
        #         ''))
        #         lib.concatStrings
        #       ]
        #     );
        #   in
        #   lib.mkIf (name == "httpd") ''
        #     rsync -a --chmod=u=rwX,go=rX /etc/taler/exhcange-db.conf $STATE_DIRECTORY/exchange-db.conf
        #     ${lib.getExe' cfg.package "taler-exchange-dbinit"} -c $STATE_DIRECTORY/exhcange-db.conf
        #     ${lib.getExe' config.services.postgresql.package "psql"} -U taler-exchange-httpd -f ${dbScript}
        #   '';
      }))
      # Database Initialisation
      {
        "taler-${talerComponent}-dbinit" = {
          path = [
            config.services.postgresql.package
            pkgs.rsync
          ];
          documentation = [
            "man:taler-${talerComponent}-dbinit(1)"
            "info:taler-${talerComponent}"
          ];
          serviceConfig = {
            Type = "oneshot";
            User = dbName;
            Group = groupName;
            RuntimeDirectory = "dbinit";
            StateDirectory = "dbinit";
            CacheDirectory = "dbinit";
            ReadWritePaths = [ runtimeDir ];
          };
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };
      }
    ];

    users.users.${dbName} = {
      home = runtimeDir;
      createHome = false;
      isSystemUser = true;
      group = groupName;
    };
    users.groups.${groupName} = { };
    systemd.tmpfiles.settings = {
      "10-taler-${talerComponent}" = {
        "${runtimeDir}" = {
          d = {
            group = groupName;
            user = "nobody";
            mode = "070";
          };
        };
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings."${talerComponent}".PORT ];
    };

    environment.systemPackages = [ cfg.package ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ dbName ];
      ensureUsers = map (service: { name = "taler-${talerComponent}-${service}"; }) servicesDB ++ [
        {
          name = dbName;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
