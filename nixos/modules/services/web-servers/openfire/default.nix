{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openfire-server;
in

{
  options.services.openfire-server = {
    enable = lib.mkEnableOption "Openfire XMPP server";
    package = lib.mkPackageOption pkgs "openfire" { };

    servicePort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = ''
        The port on which Openfire should listen for insecure Admin Console access.
      '';
    };

    securePort = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = ''
        The port on which Openfire should listen for secure Admin Console access.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to open ports in the firewall for the server.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.package}/opt";
      defaultText = lib.literalExpression ''"''${config.services.openfire.package}/opt"'';
      description = ''
        Where to load readonly data from.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openfire";
      description = ''
        Where to store runtime data (logs, plugins, ...).

        If left at the default, this will be automatically created on server
        startup if it does not already exist. If changed, it is the admin's
        responsibility to make sure that the directory exists and is writeable
        by the `openfire` user.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.openfire = {
      description = "openfire server daemon user";
      home = cfg.stateDir;
      createHome = false;
      isSystemUser = true;
      group = "openfire";
    };
    users.groups.openfire = { };

    systemd.services.openfire-server = {
      description = "Openfire Server Daemon";
      serviceConfig = lib.mkMerge [
        {
          ExecStart = "${cfg.package}/bin/openfire.sh";
          User = "openfire";
          Group = "openfire";
          Restart = "on-failure";
          WorkingDirectory = cfg.stateDir;
        }
        (lib.mkIf (cfg.stateDir == "/var/lib/openfire") {
          StateDirectory = "openfire";
        })
      ];
      environment.OPENFIRE_HOME = cfg.stateDir;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # Files under `OPENFIRE_HOME` require read-write permissions for Openfire
      # to work correctly, so we can't directly run it from the nix store.
      # As such, we need to copy those files into a directory that has proper permissions.
      # If `conf/openfire.xml` already exists, we assume the rest of the files
      # do as well, and copy nothing -- otherwise we risk ovewriting server state
      # information every time the server is upgraded.
      # TODO: how to handle package updates?
      preStart = ''
        if [ ! -e "${cfg.stateDir}"/conf/openfire.xml ]; then
          ${pkgs.rsync}/bin/rsync -a --chmod=u=rwX,go=rX \
            "${cfg.package}/opt/" "${cfg.stateDir}/"
        fi
      '';
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.servicePort
        cfg.securePort
      ];
    };
  };
}
