{
  lib,
  pkgs,
  config,
  ...
}:

let
  settingsFormat = pkgs.formats.ini { };
  this = config.services.taler;
  runtimeDir = "/run/taler-system-runtime/";
  dbNameExchange = "taler-exchange-httpd";
  dbNameLibeufin = "libeufin";
in

{
  imports = [
    ./exchange.nix
    ./libeufin.nix
  ];

  options.services.taler = {
    enable = lib.mkEnableOption "the GNU Taler system";
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
        options = {
          taler = {
            currency = lib.mkOption {
              # TODO upcase?
              type = lib.types.str;
              default = "KUDOS";
            };
            currency_round_unit = lib.mkOption {
              # TODO: refactor
              type = lib.types.str;
              default = "KUDOS:0.01";
            };
          };
          PATHS = {
            TALER_DATA_HOME = lib.mkOption {
              type = lib.types.str;
              default = "\${STATE_DIRECTORY}/";
            };
            TALER_CACHE_HOME = lib.mkOption {
              type = lib.types.str;
              default = "\${CACHE_DIRECTORY}/";
            };
            # TALER_RUNTIME_DIR = lib.mkOption { type = lib.types.str; default = "\${RUNTIME_DIRECTORY}/"; };
            TALER_RUNTIME_DIR = lib.mkOption {
              type = lib.types.str;
              default = runtimeDir; # TODO refactor into constant
            };
          };
          exchange = {
            # TODO these should be generated from high-level NixOS options
            AML_THRESHOLD = lib.mkOption {
              type = lib.types.str;
              default = "KUDOS:1000000";
            };
            MAX_KEYS_CACHING = lib.mkOption {
              type = lib.types.str;
              default = "forever";
            };
            DB = lib.mkOption {
              type = lib.types.str;
              default = "postgres";
            };
            MASTER_PUBLIC_KEY = lib.mkOption {
              type = lib.types.str;
              default = "Q6KCV81R9T3SC41T5FCACC2D084ACVH5A25FH44S6M5WXWZAA8P0";
            };
            # WIRE_RESPONSE = lib.mkOption {
            #   #type = lib.types.str;
            #   default = "\${TALER_DATA_HOME}/exchange/account-1.json";
            # };
            PORT = lib.mkOption {
              # TODO option
              type = lib.types.port;
              default = 8081;
            };
            BASE_URL = lib.mkOption {
              # TODO ensure / is present!
              type = lib.types.str;
              default = "https://exchange.hephaistos.foo.bar/";
            };
            SIGNKEY_DURATION = lib.mkOption {
              type = lib.types.str;
              default = "2 weeks";
            };
            SIGNKEY_LEGAL_DURATION = lib.mkOption {
              type = lib.types.str;
              default = "2 years";
            };
            LOOKAHEAD_SIGN = lib.mkOption {
              type = lib.types.str;
              default = "3 weeks 1 day";
            };
            KEYDIR = lib.mkOption {
              type = lib.types.str;
              default = "\${TALER_DATA_HOME}/exchange/live-keys/";
            };
            REVOCATION_DIR = lib.mkOption {
              type = lib.types.str;
              default = "\${TALER_DATA_HOME}/exchange/revocations/";
            };
            TERMS_ETAG = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
            PRIVACY_ETAG = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
          };
          exchangedb-postgres = {
            CONFIG = lib.mkOption {
              type = lib.types.str;
              default = "postgres:///${dbNameExchange}";
            };
          };
          libeufin-bank = {
            CURRENCY = lib.mkOption {
              type = lib.types.str;
              default = "KUDOS";
            };
            SERVE = lib.mkOption {
              type = lib.types.str;
              default = "tcp";
            };
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 8082;
            };
            BIND_TO = lib.mkOption {
              # TODO: set a HOSTNAME to this as well?
              type = lib.types.str;
              default = "libeufin.hephaistos.foo.bar";
            };
            WIRE_type = lib.mkOption {
              type = lib.types.str;
              default = "x-taler-bank";
            };
            #TODO: check WIRE_#type and set X_TALER_BANK_PAYTO_HOSTNAME and IBAN_PAYTO_BIC
            # If WIRE_#type = lib.mkDefault x-taler-bank
            X_TALER_BANK_PAYTO_HOSTNAME = lib.mkOption {
              type = lib.types.str;
              default = "http://libeufin.hephaistos.foo.bar:8082/";
            };
            #TODO:
            # If WIRE_#type = lib.mkDefault iban
            # IBAN_PAYTO_BIC = lib.mkOption {
            #   type = lib.types.str;
            #   default = "SANDBOXX";
            # };
            REGISTRATION_BONUS = lib.mkOption {
              type = lib.types.str;
              default = "KUDOS:100";
            };
            ALLOW_REGISTRATION = lib.mkOption {
              type = lib.types.str;
              default = "yes";
            };
            ALLOW_ACCOUNT_DELETION = lib.mkOption {
              type = lib.types.str;
              default = "yes";
            };
            #TODO: check SSL to determine http or https
            SUGGESTED_WITHDRAWAL_EXCHANGE = lib.mkOption {
              type = lib.types.str;
              default = "https://exchange.hephaistos.foo.bar:8081/";
            };
          };
          libeufin-bankdb-postgres = {
            CONFIG = lib.mkOption {
              type = lib.types.str;
              default = "postgresql:///${dbNameLibeufin}";
            };
          };
          libeufin-nexusdb-postgres = {
            CONFIG = lib.mkOption {
              type = lib.types.str;
              default = "postgresql:///${dbNameLibeufin}";
            };
          };
        };
      };
      default = { };
    };
    includes = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      description = ''
        Files to include into the config file using Taler's `@inline@` directive.

        This allows including arbitrary INI files, including imperatively managed ones.
      '';
    };
    configFile = lib.mkOption {
      internal = true;
      default =
        let
          includes = pkgs.writers.writeText "includes.conf" (
            lib.concatStringsSep "\n" (map (include: "@inline@ ${include}") this.includes)
          );
          generatedConfig = settingsFormat.generate "generated-taler.conf" this.settings;
        in
        pkgs.runCommand "taler.conf" { } ''
          cat ${includes} > $out
          echo >> $out
          echo >> $out
          cat ${generatedConfig} >> $out
        '';
    };
  };

  config = {
    environment.etc."taler/taler.conf".source = this.configFile;
  };
}
