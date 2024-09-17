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
in

talerUtils.mkTalerModule rec {
  talerComponent = "depolymerization";

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
              default = "postgres:///taler-depolymerization";
            };
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 8084;
              description = "Port on which the HTTP server listens.";
            };
          };
        };
      };
      default = { };
    };
  };

  extraConfig = {
    services.taler.settings.taler.CURRENCY = "BITCOINBTC";
  };

  extraServices = [
    # Database Initialisation
    # FIX: panics at `btc-wire/src/rpc_utils.rs:51:50`
    {
      "taler-${talerComponent}-dbinit" = {
        path = [
          config.services.postgresql.package
          cfgTaler.exchange.package
          pkgs.gnunet
          pkgs.toybox # for `which`
        ];
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        script = ''
          ${lib.getExe' cfg.package "btc-wire"} initdb
          ${lib.getExe' cfg.package "btc-wire"} initwallet
        '';
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          User = "taler-${talerComponent}";
        };
      };
    }
  ];
}
