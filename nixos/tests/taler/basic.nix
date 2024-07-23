import ../make-test-python.nix (
  { pkgs, ... }:
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

      libeufin =
        { pkgs, config, ... }:
        {
          services.libeufin.bank = {
            enable = true;
            debug = true;
            settings = {
              libeufin-bank = {
                SUGGESTED_WITHDRAWAL_EXCHANGE = "http://localhost:8081";
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
        bankConfig = toString nodes.libeufin.services.libeufin.configFile.outPath;
        talerConfig = toString nodes.exchange.services.taler.configFile.outPath;

        bankSettings = nodes.libeufin.services.libeufin.settings.libeufin-bank;

        # Bank admin account credentials
        AUSER = "admin";
        APASS = "admin";

        register_bank_account = pkgs.writeShellScript "register_bank_account" ''
          # Modified from taler-unified-setup.sh
          # https://git.taler.net/exchange.git/tree/src/testing/taler-unified-setup.sh?h=v0.11.2#n276

          set -eux
          echo "$@"
          if [ "$1" = "exchange" ] || [ "$1" = "Exchange" ]; then
              IS_EXCHANGE="true"
          else
              IS_EXCHANGE="false"
          fi
          MAYBE_IBAN="''${4:-}"
          if [ -n "$MAYBE_IBAN" ]; then
              ENAME=$(echo "$3" | sed -e "s/ /+/g")
              # Note: this assumes that $3 has no spaces. Should probably escape in the future..
              PAYTO="payto://iban/SANDBOXX/$MAYBE_IBAN?receiver-name=$ENAME"
              BODY='{"username":"'"$1"'","password":"'"$2"'","is_taler_exchange":'"$IS_EXCHANGE"',"name":"'"$3"'","payto_uri":"'"$PAYTO"'"}'
          else
              BODY='{"username":"'"$1"'","password":"'"$2"'","is_taler_exchange":'"$IS_EXCHANGE"',"name":"'"$3"'"}'
          fi
          wget \
            --http-user="${AUSER}" \
            --http-password="${APASS}" \
            --method=POST \
            --header='Content-type: application/json' \
            --body-data="$BODY" \
            -o /dev/null \
            -O /dev/null \
            -a wget-register-account.log \
            "http://localhost:${toString bankSettings.PORT}/accounts"
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

        libeufin.wait_for_unit("default.target")
        exchange.wait_for_unit("default.target")

        # Change password of admin account
        systemd_run(libeufin, "libeufin-bank passwd -c \"${bankConfig}\" \"${AUSER}\" \"${APASS}\"")

        # Increase debit amount of admin account
        systemd_run(libeufin, "libeufin-bank edit-account -c ${bankConfig} --debit_threshold=\"${bankSettings.CURRENCY}:1000000\" ${AUSER}")

        # Register bank accounts (name and IBAN are hard-coded in the testing API)
        libeufin.execute("${register_bank_account} testUser testUser \"User42\" FR7630006000011234567890189")
        libeufin.execute("${register_bank_account} exchange exchange \"Exchange Company\" DE989651")
      '';
  }
)
