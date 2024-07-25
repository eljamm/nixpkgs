import ../make-test-python.nix (
  { pkgs, lib, ... }:
  let
    CURRENCY = "KUDOS";
  in
  {
    name = "taler";
    meta = {
      maintainers = [ ];
    };

    nodes = {
      exchange =
        { pkgs, lib, ... }:
        {
          services.taler = {
            settings = {
              taler.CURRENCY = CURRENCY;
            };
            includes = [ ./conf/taler-accounts.conf ];
            exchange = {
              enable = true;
              debug = true;
              denominationConfig = lib.readFile ./conf/taler-denominations.conf;
              enableAccounts = [ ./testUser.json ];
              settings.exchange = {
                MASTER_PUBLIC_KEY = "2TQSTPFZBC2MC4E52NHPA050YXYG02VC3AB50QESM6JX1QJEYVQ0";
              };
            };
          };
        };

      bank =
        { pkgs, config, ... }:
        {
          services.libeufin.bank = {
            enable = true;
            debug = true;
            settings = {
              libeufin-bank = {
                # SUGGESTED_WITHDRAWAL_EXCHANGE = "http://localhost:8081";
                WIRE_TYPE = "iban";
                IBAN_PAYTO_BIC = "SANDBOXX";

                # Allow creating new accounts and give new accounts a starting bonus
                ALLOW_REGISTRATION = "yes";
                REGISTRATION_BONUS_ENABLED = "yes";
                REGISTRATION_BONUS = "${CURRENCY}:100";

                inherit CURRENCY;
              };
            };
          };
          environment.systemPackages = [
            pkgs.wget
            config.services.libeufin.bank.package
          ];
        };
    };

    testScript =
      { nodes, ... }:
      let
        bankConfig = toString nodes.bank.services.libeufin.configFile.outPath;
        talerConfig = toString nodes.exchange.services.taler.configFile.outPath;

        bankSettings = nodes.bank.services.libeufin.settings.libeufin-bank;

        # Bank admin account credentials
        AUSER = "admin";
        APASS = "admin";

        register_bank_account =
          {
            username,
            password,
            name,
            iban ? null,
          }:
          let
            is_taler_exchange = lib.toLower username == "exchange";
            BODY =
              {
                inherit
                  username
                  password
                  name
                  is_taler_exchange
                  ;
              }
              // lib.optionalAttrs is_taler_exchange {
                PAYTO = "payto://iban/SANDBOXX/${iban}?receiver-name=${name}";
              };
          in
          pkgs.writeShellScript "register_bank_account" ''
            # Modified from taler-unified-setup.sh
            # https://git.taler.net/exchange.git/tree/src/testing/taler-unified-setup.sh?h=v0.11.2#n276

            set -eux
            wget \
              --http-user=${AUSER} \
              --http-password=${APASS} \
              --method=POST \
              --header='Content-type: application/json' \
              --body-data=${lib.escapeShellArg (lib.strings.toJSON BODY)} \
              -o /dev/null \
              -O /dev/null \
              -a wget-register-account.log \
              "http://bank:${toString bankSettings.PORT}/accounts"
          '';
      in

      # NOTE: for NeoVim formatting and highlights. Remove later.
      # python
      ''
        def systemd_run(machine, cmd):
            machine.log(f"Executing command (via systemd-run): \"{cmd}\"")

            (status, out) = machine.execute( " ".join([
                "systemd-run",
                "--service-type=exec",
                "--quiet",
                "--wait",
                "-E PATH=\"$PATH\"",
                "-p StandardOutput=journal",
                "-p StandardError=journal",
                "-p DynamicUser=yes",
                "-p User=libeufin-bank",
                f"$SHELL -c '{cmd}'"
                ]) )

            if status != 0:
                raise Exception(f"systemd_run failed (status {status})")

            machine.log("systemd-run finished successfully")

        start_all()

        bank.wait_for_unit("default.target")
        exchange.wait_for_unit("default.target")

        # Change password of admin account
        systemd_run(bank, "libeufin-bank passwd -c \"${bankConfig}\" \"${AUSER}\" \"${APASS}\"")

        # Increase debit amount of admin account
        systemd_run(bank, "libeufin-bank edit-account -c ${bankConfig} --debit_threshold=\"${bankSettings.CURRENCY}:1000000\" ${AUSER}")

        # Register bank accounts (name and IBAN are hard-coded in the testing API)
        bank.execute("${
          register_bank_account {
            username = "testUser";
            password = "testUser";
            name = "User42";
            iban = "FR7630006000011234567890189";
          }
        }")
        bank.execute("${
          register_bank_account {
            username = "exchange";
            password = "exchange";
            name = "Exchange Company";
            iban = "DE989651";
          }
        }")
      '';
  }
)
