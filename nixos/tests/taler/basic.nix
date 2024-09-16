import ../make-test-python.nix (
  { pkgs, lib, ... }:
  let
    CURRENCY = "KUDOS";

    # Enable SSH on machine, recursively merge with settings
    #
    # Connect with: ssh root@localhost -p <hostPort>
    enableSSH =
      hostPort: settings:
      lib.recursiveUpdate {
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = hostPort; # ssh
            guest.port = 22;
          }
        ];
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
    name = "taler";
    meta = {
      maintainers = [ ];
    };

    nodes = {
      exchange =
        { config, lib, ... }:
        enableSSH 1111 {
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
                BASE_URL = "http://exchange:8081/";
              };
              settings.exchange-offline = {
                MASTER_PRIV_FILE = "${./private.key}";
              };
            };
          };
          networking.firewall.enable = false;
          environment.systemPackages = [ config.services.taler.exchange.package ];
        };

      merchant =
        { config, ... }:
        enableSSH 2222 {
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
              host.port = 8083;
              guest.port = 8083;
            }
          ];
        };

      bank =
        { config, pkgs, ... }:
        enableSSH 3333 {
          services.libeufin.bank = {
            enable = true;
            debug = true;
            settings = {
              libeufin-bank = {
                # SUGGESTED_WITHDRAWAL_EXCHANGE = "http://exchange:8081";
                WIRE_TYPE = "x-taler-bank";
                X_TALER_BANK_PAYTO_HOSTNAME = "bank:8082";

                # Allow creating new accounts
                ALLOW_REGISTRATION = "yes";

                # A registration bonus makes withdrawals easier since the
                # bank account balance is not empty
                REGISTRATION_BONUS_ENABLED = "yes";
                REGISTRATION_BONUS = "${CURRENCY}:100";

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
              host.port = 8082;
              guest.port = 8082;
            }
          ];
        };

      client =
        { pkgs, ... }:
        enableSSH 4444 {
          networking.firewall.enable = false;
          environment.systemPackages = [ pkgs.taler-wallet-core ];
        };

    };

    # TODO: split this into many separate tests
    testScript =
      { nodes, ... }:
      let
        bankConfig = toString nodes.bank.services.libeufin.configFile.outPath;

        bankSettings = nodes.bank.services.libeufin.settings.libeufin-bank;
        nexusSettings = nodes.bank.services.libeufin.settings.nexus-ebics;

        # Bank admin account credentials
        AUSER = "admin";
        APASS = "admin";

        TUSER = "testUser";
        TPASS = "testUser";

        # TODO: Move scripts to separate directory?
        register_bank_account =
          {
            username,
            password,
            name,
          }:
          let
            is_taler_exchange = lib.toLower username == "exchange";
            BODY = lib.escapeShellArg (
              lib.strings.toJSON {
                inherit
                  username
                  password
                  name
                  is_taler_exchange
                  ;
              }
            );
          in
          pkgs.writeShellScript "register_bank_account" ''
            # Modified from taler-unified-setup.sh
            # https://git.taler.net/exchange.git/tree/src/testing/taler-unified-setup.sh

            set -eux
            curl \
              -X POST \
              -H "Content-type: application/json" \
              -u ${AUSER}:${APASS} \
              --data ${BODY} \
              --silent \
              --output /dev/null \
              "http://bank:8082/accounts"
          '';

        nexus_fake_incoming = pkgs.writeShellScript "nexus_fake_incoming" ''
          set -eux
          RESERVE_PUB=$(
            taler-wallet-cli \
              api 'acceptManualWithdrawal' \
                '{"exchangeBaseUrl":"http://exchange:8081/",
                  "amount":"${nexusSettings.CURRENCY}:20"
                 }' | jq -r .result.reservePub
            )

          libeufin-nexus \
            testing fake-incoming \
            -c ${bankConfig} \
            --amount="${nexusSettings.CURRENCY}:20" \
            --subject="$RESERVE_PUB" \
            "payto://iban/CH8389144317421994586"
        '';
      in

      # NOTE: for NeoVim formatting and highlights. Remove later.
      # python
      ''
        import json

        # Join curl commands
        # TODO: add option to fail on unexpected return code?
        def curl(machine, commands):
            return machine.succeed(" ".join(commands))

        # Execute command as systemd DynamicUser
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

        # Wallet wrapper
        def wallet_cli(command):
            return client.succeed(
                "taler-wallet-cli "
                "--no-throttle "    # don't do any request throttling
                + command
            )

        def verify_balance(balanceWanted):
            balance = wallet_cli("balance --json")
            try:
                balanceGot = json.loads(balance)["balances"][0]["available"]
            except:
                balanceGot = "${CURRENCY}:0"

            # Compare balance with expected value
            if balanceGot != balanceWanted:
                client.fail(f'echo Wanted balance: "{balanceWanted}", got: "{balanceGot}"')
            else:
                client.succeed(f"echo Withdraw successfully made. New balance: {balanceWanted}")


        start_all()


        bank.wait_for_open_port(8082)
        exchange.wait_for_open_port(8081)
        merchant.wait_for_open_port(8083)


        with subtest("Enable exchange wire account"):
            exchange.wait_until_succeeds("taler-exchange-offline download sign upload")
            exchange.succeed('taler-exchange-offline enable-account "payto://x-taler-bank/bank:8082/exchange?receiver-name=exchange" upload')


        with subtest("Modify bank's admin account"):
            # Change password
            systemd_run(bank, 'libeufin-bank passwd -c "${bankConfig}" "${AUSER}" "${APASS}"', "libeufin-bank")

            # Increase debit amount
            systemd_run(bank, 'libeufin-bank edit-account -c ${bankConfig} --debit_threshold="${bankSettings.CURRENCY}:1000000" ${AUSER}', "libeufin-bank")


        bank.succeed("curl -s http://exchange:8081/")


        with subtest("Register bank accounts"):
        # NOTE: using hard-coded values from the testing API
        # TODO: add link to testing API
            bank.succeed("${
              register_bank_account {
                username = "${TUSER}";
                password = "${TPASS}";
                name = "User42";
              }
            }")
            bank.succeed("${
              register_bank_account {
                username = "exchange";
                password = "exchange";
                name = "Exchange Company";
              }
            }")
            bank.succeed("${
              register_bank_account {
                username = "merchant";
                password = "merchant";
                name = "merchant";
              }
            }")
            # WIP:
            systemd_run(bank, 'libeufin-bank edit-account -c ${bankConfig} --debit_threshold="${bankSettings.CURRENCY}:1000000" exchange', "libeufin-bank")
            systemd_run(bank, 'libeufin-bank edit-account -c ${bankConfig} --debit_threshold="${bankSettings.CURRENCY}:1000000" merchant', "libeufin-bank")


        with subtest("Register merchant instances"):
            curl(merchant, [
                "curl -X POST",
                "-H 'Authorization: Bearer secret-token:super_secret'",
                """
                --data '{
                  "auth": { "method": "external" },
                  "id": "default",
                  "name": "default",
                  "user_type": "business",
                  "address": {},
                  "jurisdiction": {},
                  "use_stefan": true,
                  "default_wire_transfer_delay": { "d_us": 3600000000 },
                  "default_pay_delay": { "d_us": 3600000000 }
                }'
                """.replace("\n", ""),
                "-sSfL 'http://merchant:8083/management/instances'"
            ])
            # WIP:
            # Register bank account address
            # curl(merchant, [
            #     "curl -X POST",
            #     "-H 'Content-Type: application/json'",
            #     """
            #     --data '{
            #       "payto_uri": "payto://iban/DE5532534346932?receiver-name=nixMerchant",
            #       "credit_facade_url": "https://bank.demo.taler.net/accounts/nixMerchant/taler-revenue/",
            #       "credit_facade_credentials":{"type":"basic","username":"nixMerchant","password":"nixMerchant"}
            #     }'
            #     """.replace("\n", ""),
            #     "-sSfL 'http://merchant:8083/private/accounts'"
            # ])
            curl(merchant, [
                "curl -X POST",
                "-H 'Content-Type: application/json'",
                """
                --data '{
                  "payto_uri": "payto://x-taler-bank/bank:8082/merchant?receiver-name=merchant",
                  "credit_facade_url": "http://localhost:8082/accounts/merchant/taler-revenue/",
                  "credit_facade_credentials":{"type":"basic","username":"merchant","password":"merchant"}
                }'
                """.replace("\n", ""),
                "-sSfL 'http://merchant:8083/private/accounts'"
            ])


        client.succeed("curl -s http://exchange:8081/")


        # WIP:
        # wallet_cli("""api --expect-success 'withdrawTestBalance' '{ "amount": "KUDOS:10", "corebankApiBaseUrl": "http://bank:8082/", "exchangeBaseUrl": "http://exchange:8081/" }'""")
        # wallet_cli("""api 'runIntegrationTestV2' '{"exchangeBaseUrl":"http://exchange:8081/", "corebankApiBaseUrl": "http://bank:8082/", "merchantBaseUrl": "https://merchant:8083/", "merchantAuthToken":"secret-token:sandbox"}'""")
        # wallet_cli("run-until-done")


        # Make a withdrawal from the CLI wallet
        with subtest("Make a withdrawal from the CLI wallet"):
            balanceWanted = "${CURRENCY}:10"

            # Register exchange
            with subtest("Register exchange"):
                wallet_cli("exchanges add http://exchange:8081/")
                wallet_cli("exchanges accept-tos http://exchange:8081/")

            # Request withdrawal from the bank
            withdrawal = json.loads(
                curl(client, [
                    "curl -X POST",
                    "-u ${TUSER}:${TPASS}",
                    "-H 'Content-Type: application/json'",
                    f"""--data '{{"amount": "{balanceWanted}"}}'""", # double brackets escapes them
                    "-sSfL 'http://bank:8082/accounts/${TUSER}/withdrawals'"
                ])
            )

            # Accept & confirm withdrawal
            with subtest("Accept & confirm withdrawal"):
                wallet_cli(f"withdraw accept-uri {withdrawal["taler_withdraw_uri"]} --exchange http://exchange:8081/")
                curl(client, [
                    "curl -X POST",
                    "-u ${TUSER}:${TPASS}",
                    "-H 'Content-Type: application/json'",
                    f"-sSfL 'http://bank:8082/accounts/${TUSER}/withdrawals/{withdrawal["withdrawal_id"]}/confirm'"
                ])

            # Process transactions
            wallet_cli("run-until-done")

            verify_balance(balanceWanted)


        breakpoint()
        with subtest("Pay for an order"):
            balanceWanted = "${CURRENCY}:9" # after paying

            # Register a new product
            curl(merchant, [
                "curl -X POST",
                "-H 'Content-Type: application/json'",
                """
                --data '{
                  "product_id": "1",
                  "description": "Product with id 1 and price 1",
                  "price": "KUDOS:1",
                  "total_stock": 20,
                  "unit": "packages",
                  "next_restock": { "t_s": "never" }
                }'
                """.replace("\n", ""),
                "-sSfL 'http://merchant:8083/private/products'"
            ])
            # Create an order to be paid
            response = json.loads(
                curl(merchant, [
                    "curl -X POST",
                    "-H 'Content-Type: application/json'",
                    """
                    --data '{
                      "order": { "amount": "KUDOS:1", "summary": "Test Order" },
                      "inventory_products": [{ "product_id": "1", "quantity": 1 }]
                    }'
                    """.replace("\n", ""),
                    "-sSfL 'http://merchant:8083/private/orders'"
                ])
            )
            order_id = response["order_id"]
            token = response["token"]

            # Get order pay URI
            response = json.loads(
                curl(merchant, [
                    "curl -sSfL",
                    f"http://merchant:8083/private/orders/{order_id}"
                ])
            )
            wallet_cli("run-until-done")

            # Process transaction
            wallet_cli(f"handle-uri -y '{response["taler_pay_uri"]}'")
            wallet_cli("run-until-done")

            verify_balance(balanceWanted)


        # with subtest("Nexus fake incoming payment"):
        #     # Setup ebics keys
        #     bank.succeed("libeufin-nexus ebics-setup -L debug -c ${bankConfig}")
        #
        #     # Make fake transaction
        #     systemd_run(bank, "${nexus_fake_incoming}", "libeufin-nexus")
        #     wallet_cli("run-until-done")
      '';
  }
)
