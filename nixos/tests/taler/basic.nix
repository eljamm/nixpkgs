import ../make-test-python.nix (
  { pkgs, lib, ... }:
  let
    cfgNodes = pkgs.callPackage ./common/nodes.nix { inherit lib; };
  in
  {
    name = "Taler Basic Test";
    meta = {
      maintainers = [ ];
    };

    # Taler components virtual-machine nodes
    nodes = {
      inherit (cfgNodes.nodes)
        bank
        client
        exchange
        merchant
        ;
    };

    # TODO: make separate tests (i.e. for each component)?
    testScript =
      { nodes, ... }:
      let
        cfgScripts = pkgs.callPackage ./common/scripts.nix { inherit lib pkgs nodes; };

        inherit (cfgNodes) CURRENCY;
        inherit (cfgScripts) commonScripts nexus_fake_incoming;

        bankConfig = toString nodes.bank.services.libeufin.configFile.outPath;
        bankSettings = nodes.bank.services.libeufin.settings.libeufin-bank;

        # Bank admin account credentials
        AUSER = "admin";
        APASS = "admin";

        TUSER = "testUser";
        TPASS = "testUser";
      in

      # NOTE: for NeoVim formatting and highlights. Remove later.
      # python
      ''
        import json

        # import common scripts
        ${commonScripts}

        # NOTE: it's better if the bank is confiugured first
        bank.start()
        bank.wait_for_open_port(8082)


        with subtest("Set up Libeufin bank"):
            # Modify admin account password, increase debit threshold
            systemd_run(bank, 'libeufin-bank passwd -c "${bankConfig}" "${AUSER}" "${APASS}"', "libeufin-bank")
            systemd_run(bank, 'libeufin-bank edit-account -c ${bankConfig} --debit_threshold="${bankSettings.CURRENCY}:1000000" ${AUSER}', "libeufin-bank")

            with subtest("Register bank accounts"):
                # username, password, name
                register_bank_account("testUser", "testUser", "User")
                register_bank_account("exchange", "exchange", "Exchange")
                register_bank_account("merchant", "merchant", "Merchant")


        start_all()

        exchange.wait_for_open_port(8081)
        merchant.wait_for_open_port(8083)


        with subtest("Set up exchange"):
            exchange.wait_until_succeeds("taler-exchange-offline download sign upload")
            # Enable exchange wire account
            exchange.succeed('taler-exchange-offline upload < ${./conf/exchange-account.json}')

            # NOTE: cannot deposit coins/pay merchant if wire fees are not set up
            exchange.succeed('taler-exchange-offline wire-fee now x-taler-bank "${CURRENCY}:0" "${CURRENCY}:0" upload')
            exchange.succeed('taler-exchange-offline global-fee now "${CURRENCY}:0" "${CURRENCY}:0" "${CURRENCY}:0" 1h 6a 0 upload')


        # Verify that exchange keys exist
        bank.succeed("curl -s http://exchange:8081/keys")


        with subtest("Set up merchant"):
            # Create default instance (similar to admin)
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
                """,
                "-sSfL 'http://merchant:8083/management/instances'"
            ])
            # Register bank account address
            curl(merchant, [
                "curl -X POST",
                "-H 'Content-Type: application/json'",
                """
                --data '{
                  "payto_uri": "payto://x-taler-bank/bank:8082/merchant?receiver-name=Merchant",
                  "credit_facade_url": "http://bank:8082/accounts/merchant/taler-revenue/",
                  "credit_facade_credentials":{"type":"basic","username":"merchant","password":"merchant"}
                }'
                """,
                "-sSfL 'http://merchant:8083/private/accounts'"
            ])
            # Register a new product to be ordered
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
                """,
                "-sSfL 'http://merchant:8083/private/products'"
            ])


        client.succeed("curl -s http://exchange:8081/")


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


        with subtest("Pay for an order"):
            balanceWanted = "${CURRENCY}:9" # after paying

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
                    """,
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
            wallet_cli(f"""handle-uri -y '{response["taler_pay_uri"]}'""")
            wallet_cli("run-until-done")

            verify_balance(balanceWanted)


        # TODO:
        # with subtest("Nexus fake incoming payment"):
        #     # Setup ebics keys
        #     bank.succeed("libeufin-nexus ebics-setup -L debug -c ${bankConfig}")
        #     # Make fake transaction
        #     systemd_run(bank, "${nexus_fake_incoming}", "libeufin-nexus")
        #     wallet_cli("run-until-done")
      '';
  }
)
