{ lib, ... }:
let
  CURRENCY = "KUDOS";

  # Enable SSH on machine, recursively merge with settings
  #
  # Connect with: ssh root@localhost -p <hostPort>
  enableSSH =
    settings:
    lib.recursiveUpdate {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "yes";
          PermitEmptyPasswords = "yes";
        };
      };
      security.pam.services.sshd.allowNullPassword = true;
    } settings;
in
{
  nodes = {
    exchange =
      { config, lib, ... }:
      enableSSH {
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
        # Access from http://localhost:8081/
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 1111;
            guest.port = 22;
          }
          {
            from = "host";
            host.port = 8081;
            guest.port = 8081;
          }
        ];
      };

    merchant =
      { config, ... }:
      enableSSH {
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
        # Access WebUI from http://localhost:8083/
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
          {
            from = "host";
            host.port = 8083;
            guest.port = 8083;
          }
        ];
      };

    bank =
      { config, pkgs, ... }:
      enableSSH {
        services.libeufin.bank = {
          enable = true;
          debug = true;
          settings = {
            libeufin-bank = {
              WIRE_TYPE = "x-taler-bank";
              # WIRE_TYPE = "iban";
              X_TALER_BANK_PAYTO_HOSTNAME = "bank:8082";
              # IBAN_PAYTO_BIC = "SANDBOXX";

              # Allow creating new accounts
              ALLOW_REGISTRATION = "yes";

              # A registration bonus makes withdrawals easier since the
              # bank account balance is not empty
              REGISTRATION_BONUS_ENABLED = "yes";
              REGISTRATION_BONUS = "${CURRENCY}:100";

              DEFAULT_DEBT_LIMIT = "${CURRENCY}:500";

              # ALLOW_CONVERSION = "yes";
              # ALLOW_EDIT_CASHOUT_PAYTO_URI = "yes";

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
        # Access WebUI from http://localhost:8082/
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 3333;
            guest.port = 22;
          }
          {
            from = "host";
            host.port = 8082;
            guest.port = 8082;
          }
        ];
      };

    client =
      { pkgs, ... }:
      enableSSH {
        networking.firewall.enable = false;
        environment.systemPackages = [ pkgs.taler-wallet-core ];
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 4444;
            guest.port = 22;
          }
        ];
      };
  };

}
