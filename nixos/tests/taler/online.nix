# NOTE: this test requires internet connection, so you must run it interactively:
#
# eval $(nix-build -A driverInteractive nixos/tests/taler/online.nix)/bin/nixos-test-driver

import ../make-test-python.nix (
  { pkgs, lib, ... }:
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
    name = "Taler Online Demo Test";
    meta = {
      maintainers = [ ];
    };

    nodes = {
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
                EXCHANGE_BASE_URL = "https://exchange.demo.taler.net/";
                MASTER_KEY = "F80MFRG8HVH6R9CQ47KRFQSJP3T6DBJ4K1D9B703RJY3Z39TBMJ0";
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

    testScript = # python
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


        merchant.start()
        client.start()

        merchant.wait_for_open_port(8083)

        merchant.succeed("curl -s https://exchange.demo.taler.net/")


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
            # Register bank account address
            curl(merchant, [
                "curl -X POST",
                "-H 'Content-Type: application/json'",
                """
                --data '{
                  "payto_uri": "payto://iban/DE5532534346932?receiver-name=nixMerchant",
                  "credit_facade_url": "https://bank.demo.taler.net/accounts/nixMerchant/taler-revenue/",
                  "credit_facade_credentials":{"type":"basic","username":"nixMerchant","password":"nixMerchant"}
                }'
                """.replace("\n", ""),
                "-sSfL 'http://merchant:8083/private/accounts'"
            ])


        client.succeed("curl -s https://exchange.demo.taler.net/")

        # Register exchange
        with subtest("Register exchange"):
            wallet_cli("exchanges add https://exchange.demo.taler.net/")
            wallet_cli("exchanges accept-tos https://exchange.demo.taler.net/")

        with subtest("Make a withdrawal from the CLI wallet"):
            balanceWanted = "${CURRENCY}:10"

            wallet_cli("""api --expect-success 'withdrawTestBalance' '{ "amount": "KUDOS:10", "corebankApiBaseUrl": "https://bank.demo.taler.net/", "exchangeBaseUrl": "https://exchange.demo.taler.net/" }'""")
            wallet_cli("run-until-done")

            verify_balance(balanceWanted)

        with subtest("Pay for an order"):
            balanceWanted = "${CURRENCY}:8.99" # 1 for order + 0.01 fees

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
            wallet_cli(f"""handle-uri --withdrawal-exchange="https://exchange.demo.taler.net/" -y '{response["taler_pay_uri"]}'""")
            wallet_cli("run-until-done")

            verify_balance(balanceWanted)
      '';
  }
)
