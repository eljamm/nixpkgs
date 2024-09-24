{ lib, ... }:
let
  # Forward SSH and WebUI ports to host machine
  #
  # Connect with: ssh root@localhost -p <hostPort>
  # Access WebUI from: http://localhost:<hostPort>
  #
  # NOTE: This is only accessible from an interactive test, for example:
  # $ eval $(nix-build -A nixosTests.taler.basic.driver)/bin/nixos-test-driver
  mkNode =
    {
      sshPort ? 0,
      webuiPort ? 0,
      nodeSettings ? { },
    }:
    lib.recursiveUpdate {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "yes";
          PermitEmptyPasswords = "yes";
        };
      };
      security.pam.services.sshd.allowNullPassword = true;
      virtualisation.forwardPorts =
        (lib.optionals (sshPort != 0) [
          {
            from = "host";
            host.port = sshPort;
            guest.port = 22;
          }
        ])
        ++ (lib.optionals (webuiPort != 0) [
          {
            from = "host";
            host.port = webuiPort;
            guest.port = webuiPort;
          }
        ]);
    } nodeSettings;
in
rec {
  CURRENCY = "KUDOS";

  nodes = {
    exchange =
      { config, lib, ... }:
      mkNode {
        sshPort = 1111;
        webuiPort = 8081;

        nodeSettings = {
          services.taler = {
            settings = {
              taler.CURRENCY = CURRENCY;
            };
            includes = [ ../conf/taler-accounts.conf ];
            exchange = {
              enable = true;
              debug = true;
              denominationConfig = lib.readFile ../conf/taler-denominations.conf;
              enableAccounts = [ ../conf/exchange-account.json ];
              settings.exchange = {
                MASTER_PUBLIC_KEY = "2TQSTPFZBC2MC4E52NHPA050YXYG02VC3AB50QESM6JX1QJEYVQ0";
                BASE_URL = "http://exchange:8081/";
              };
              settings.exchange-offline = {
                MASTER_PRIV_FILE = "${../conf/private.key}";
              };
            };
          };
          networking.firewall.enable = false;
          environment.systemPackages = [ config.services.taler.exchange.package ];
        };
      };

    bank =
      { config, ... }:
      mkNode {
        sshPort = 2222;
        webuiPort = 8082;

        nodeSettings = {
          services.libeufin.bank = {
            enable = true;
            debug = true;
            settings = {
              libeufin-bank = {
                WIRE_TYPE = "x-taler-bank";
                # WIRE_TYPE = "iban";
                X_TALER_BANK_PAYTO_HOSTNAME = "bank:8082";
                # IBAN_PAYTO_BIC = "SANDBOXX";
                BASE_URL = "bank:8082";

                # Allow creating new accounts
                ALLOW_REGISTRATION = "yes";

                # A registration bonus makes withdrawals easier since the
                # bank account balance is not empty
                REGISTRATION_BONUS_ENABLED = "yes";
                REGISTRATION_BONUS = "${CURRENCY}:100";

                DEFAULT_DEBT_LIMIT = "${CURRENCY}:500";

                # ALLOW_CONVERSION = "yes";
                ALLOW_EDIT_CASHOUT_PAYTO_URI = "yes";

                SUGGESTED_WITHDRAWAL_EXCHANGE = "http://exchange:8081/";

                inherit CURRENCY;
              };
            };
          };

          services.libeufin.nexus = {
            enable = true;
            debug = true;
            settings = {
              nexus-ebics = {
                # == Mandatory ==
                inherit CURRENCY;
                # Bank
                HOST_BASE_URL = "http://bank:8082/";
                BANK_DIALECT = "postfinance";
                # EBICS IDs
                HOST_ID = "PFEBICS";
                USER_ID = "PFC00563";
                PARTNER_ID = "PFC00563";
                # Account information
                IBAN = "CH7789144474425692816";
                BIC = "POFICHBEXXX";
                NAME = "John Smith S.A.";

                # == Optional ==
                CLIENT_PRIVATE_KEYS_FILE = "/var/lib/libeufin-nexus/client-ebics-keys.json";
              };
              libeufin-nexusdb-postgres.CONFIG = "postgresql:///libeufin-nexus";
            };
          };
          networking.firewall.enable = false;
          environment.systemPackages = [ config.services.libeufin.bank.package ];
        };
      };

    merchant =
      { config, ... }:
      mkNode {
        sshPort = 3333;
        webuiPort = 8083;

        nodeSettings = {
          services.taler = {
            settings = {
              taler.CURRENCY = CURRENCY;
            };
            merchant = {
              enable = true;
              debug = true;
              settings.merchant-exchange-test = {
                EXCHANGE_BASE_URL = "http://exchange:8081/";
                MASTER_KEY = "2TQSTPFZBC2MC4E52NHPA050YXYG02VC3AB50QESM6JX1QJEYVQ0";
                inherit CURRENCY;
              };
            };
          };
          networking.firewall.enable = false;
          environment.systemPackages = [ config.services.taler.merchant.package ];
        };
      };

    client =
      { pkgs, ... }:
      mkNode {
        sshPort = 4444;

        nodeSettings = {
          networking.firewall.enable = false;
          environment.systemPackages = [ pkgs.taler-wallet-core ];
        };
      };

    depolymerization =
      { config, ... }:
      mkNode {
        sshPort = 5555;
        webuiPort = 8084;

        nodeSettings = {
          services.taler = {
            settings.taler.CURRENCY = "BITCOINBTC";
            depolymerization = {
              enable = true;
              debug = true;
              settings = {
                depolymerizer-bitcoin = {
                  AUTH_METHOD = "basic";
                  AUTH_TOKEN = "YWRtaW46cGFzc3dvcmQ=";
                };
              };
            };
          };
          networking.firewall.enable = false;
          environment.systemPackages = [ config.services.taler.depolymerization.package ];
        };
      };
  };

}
