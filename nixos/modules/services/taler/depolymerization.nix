{
  lib,
  config,
  options,
  pkgs,
  ...
}:

let
  talerUtils = import ./utils.nix { inherit lib pkgs config; };

  cfg = cfgTaler.depolymerization;
  cfgTaler = config.services.taler;

  talerComponent = "depolymerization";
  dbName = "taler-${talerComponent}-httpd";

  inherit (cfgTaler) runtimeDir;
in

talerUtils.mkTalerModule rec {
  inherit talerComponent;

  # Services that need access to the DB
  # https://git.taler.net/depolymerization.git/about/
  servicesDB = [
    "btc-wire"
    "wire-gateway"
  ];

  extraOptions = {
    services.taler.${talerComponent}.settings = lib.mkOption {
      description = ''
        Configuration options for the taler depolymerization config file.

        For an example configuration, please see [`taler-btc-full.conf`](https://git.taler.net/depolymerization.git/about/docs/taler-btc-full.conf) and [`taler-eth-full.conf`](https://git.taler.net/depolymerization.git/about/docs/taler-eth-full.conf).
      '';
      type = lib.types.submodule {
        inherit (options.services.taler.settings.type.nestedTypes) freeformType;
        options = {
          # TODO: only allow valid currencies
          # https://git.taler.net/depolymerization.git/about/#currency
          depolymerizer-bitcoin = {
            DB_URL = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "postgres://%2Fvar%2Frun%2Fpostgresql/${dbName}?user=${dbName}";
            };
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 8084;
              description = "Port on which the HTTP server listens.";
            };
            CONF_PATH = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "/etc/taler/taler.conf";
            };
          };
        };
      };
      default = { };
    };
  };

  extraConfig = {
    services.taler.settings.taler.CURRENCY = "BITCOINBTC";

    # TODO: requires `bitcoind` with `txindex` to be running
    # services.bitcoind.taler.enable = true;
  };

  # Database Initialisation
  dbInit = {
    script = ''
      ${lib.getExe' cfg.package "btc-wire"} initdb -c ${cfgTaler.configFile}
      ${lib.getExe' cfg.package "btc-wire"} initwallet -c ${cfgTaler.configFile}
    '';
    path = [
      config.services.postgresql.package
      cfgTaler.exchange.package
      pkgs.gnunet
      pkgs.toybox # for `which`
    ];
  };
}
