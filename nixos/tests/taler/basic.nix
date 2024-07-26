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
              enableAccounts = [ ./exchange-account.json ];
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
                # SUGGESTED_WITHDRAWAL_EXCHANGE = "http://exchange:8081";
                WIRE_TYPE = "x-taler-bank";
                X_TALER_BANK_PAYTO_HOSTNAME = "http://bank:8082/";

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

      client =
        { pkgs, lib, ... }:
        {
          environment.systemPackages = [ pkgs.taler-wallet-core ];
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

        TUSER = "testUser";
        TPASS = "testUser";

        register_bank_account =
          {
            username,
            password,
            name,
          }:
          let
            is_taler_exchange = lib.toLower username == "exchange";
            BODY = {
              inherit
                username
                password
                name
                is_taler_exchange
                ;
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
        import json

        def systemd_run(machine, cmd, user="nobody", group="nobody"):
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
                f"-p Group={group}" if group != "nobody" else "",
                f"-p User={user}" if user != "nobody" else "",
                f"$SHELL -c '{cmd}'"
                ]) )

            if status != 0:
                raise Exception(f"systemd_run failed (status {status})")

            machine.log("systemd-run finished successfully")

        start_all()

        bank.wait_for_unit("default.target")
        exchange.wait_for_unit("default.target")

        # Change password of admin account
        systemd_run(bank, "libeufin-bank passwd -c \"${bankConfig}\" \"${AUSER}\" \"${APASS}\"", "libeufin-bank")

        # Increase debit amount of admin account
        systemd_run(bank, "libeufin-bank edit-account -c ${bankConfig} --debit_threshold=\"${bankSettings.CURRENCY}:1000000\" ${AUSER}", "libeufin-bank")

        # Register bank accounts (name and IBAN are hard-coded in the testing API)
        bank.execute("${
          register_bank_account {
            username = "${TUSER}";
            password = "${TPASS}";
            name = "User42";
          }
        }")
        bank.execute("${
          register_bank_account {
            username = "exchange";
            password = "exchange";
            name = "Exchange Company";
          }
        }")

        # Make a withdrawal
        client.wait_until_succeeds("taler-wallet-cli exchanges add http://exchange:8081/")
        client.execute("taler-wallet-cli exchanges accept-tos http://exchange:8081/")
        withdrawal = json.loads(
            client.succeed("curl http://bank:8082/accounts/${TUSER}/withdrawals --basic -u ${TUSER}:${TPASS} -X POST -H 'Content-Type: application/json' --data '{\"amount\": \"${CURRENCY}:25\"}'")
        )
        client.execute(f"taler-wallet-cli withdraw accept-uri {withdrawal["taler_withdraw_uri"]} --exchange http://exchange:8081/")
        client.execute(f"curl -sSfL -X POST -H 'Content-Type: application/json' 'http://bank:8082/accounts/user/withdrawals/{withdrawal["withdrawal_id"]}/confirm'")
        client.execute("taler-wallet-cli run-until-done")
      '';
  }
)
