{
  lib,
  pkgs,
  nodes,
  ...
}:

let
  cfgNodes = pkgs.callPackage ./nodes.nix { inherit lib; };
  bankConfig = nodes.bank.services.libeufin.configFile.outPath;

  inherit (cfgNodes) CURRENCY FIAT_CURRENCY;
in
{
  commonScripts =
    # NOTE: for NeoVim formatting and highlights. Remove later.
    # python
    ''
      # Join curl commands
      # TODO: add option for expected return code or is `succeed()` and `fail()` enough?
      def curl(machine, commands):
          # flatten multi-line commands
          flattened_commands = [c.replace("\n", "") for c in commands]
          return machine.succeed(" ".join(flattened_commands))

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

      def register_bank_account(username, password, name, is_exchange=False):
          return systemd_run(bank, " ".join([
              'libeufin-bank',
              'create-account',
              '-c ${bankConfig}',
              f'--username {username}',
              f'--password {password}',
              f'--name {name}',
              f'--payto_uri="payto://x-taler-bank/bank:8082/{username}?receiver-name={name}"',
              '--exchange' if (is_exchange or username.lower()=="exchange") else ' '
              ]),
              user="libeufin-bank")

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

      def verify_conversion(regionalWanted):
          # Get transaction details
          response = json.loads(
              curl(bank, [
                  "curl -sSfL",
                  "-u exchange:exchange",
                  "http://bank:8082/accounts/exchange/transactions"
              ])
          )
          amount = response["transactions"][0]["amount"].split(":") # CURRENCY:VALUE
          currencyGot = amount[0]
          regionalGot = amount[1]

          # Check conversion (1:1 ratio)
          if (regionalGot != str(regionalWanted)) or (currencyGot != "${CURRENCY}"):
              client.fail(f'echo Wanted "${CURRENCY}:{regionalWanted}", got: "{currencyGot}:{regionalGot}"')
          else:
              client.succeed(f'echo Conversion successfully made: "${FIAT_CURRENCY}:{regionalWanted}" -> "{currencyGot}:{regionalGot}"')
    '';
}
