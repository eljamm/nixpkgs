{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,

  # tests
  expect,
  runCommand,
  writeScriptBin,
}:

buildGoModule (finalAttrs: {
  pname = "dutctl";
  version = "1.0.0-alpha.1-unstable-2026-05-21";

  src = fetchFromGitHub {
    owner = "BlindspotSoftware";
    repo = "dutctl";
    rev = "710bbcd16264e62af932698a229f9be2f83f6286";
    hash = "sha256-SJfnUUo5vmmwa8qFLY4KaVyjyVnlEcVqLU1Yo3PjWug=";
  };

  vendorHash = "sha256-vOBz9gi/cnUJ04ns1ZOgfNqzbVBE3Fd3oOfV04VSmFQ=";

  ldflags = [
    "-s"
  ];

  passthru = {
    updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

    tests =
      let
        interactive-test = writeScriptBin "repeat-test" ''
          #!${expect}/bin/expect -f

          spawn dutctl device2 repeat

          expect {
            "Hello from dummy repeat module!" {}
            timeout { puts "FAIL: no greeting"; exit 1 }
          }

          send "hello\r"
          expect {
            "hello" {}
            timeout { puts "FAIL: no echo"; exit 1 }
          }

          send "stop now\r"
          expect {
            "Oh no! Can only handle one word per line." {}
            timeout { puts "FAIL: no termination msg"; exit 1 }
          }

          # wait for the process to finish and collect its exit code
          expect eof
          lassign [wait] pid spawnid os_error exit_code

          if {$exit_code != 0} {
            puts "FAIL: exit $exit_code"
            exit 1
          }

          puts "PASS: interactive repeat"
        '';
      in
      runCommand "test-dutctl-basic"
        {
          nativeBuildInputs = [
            finalAttrs.finalPackage
            interactive-test
          ];
        }
        ''
          cfg="${finalAttrs.src}/contrib/dutagent-cfg-example.yaml"

          # start agent
          dutagent -a localhost:1024 -c "$cfg" &
          agent_pid=$!
          trap 'kill "$agent_pid" 2>/dev/null || true' EXIT

          # wait for agent to become ready
          for i in $(seq 1 10); do
            dutctl list 2>/dev/null | grep -q device1 && break
            [ "$i" -eq 10 ] && { echo "FAIL: agent timed out"; exit 1; }
            sleep 1
          done
          echo "PASS: agent ready"

          # verify device status
          dutctl device1 status > status.out
          grep -q "Hello from dummy status module" status.out
          echo "PASS: device1 status"

          # run interactive repeat test
          repeat-test

          touch $out
        '';
  };

  __structuredAttrs = true;

  meta = {
    description = "Command-line utility for remote hardware access";
    longDescription = ''
      dutctl stands for "Device-under-Test Control" and is an open-source
      command-line utility and service ecosystem for managing development and
      test devices in firmware environments.

      By providing a unified interface to interact with boards and test
      fixtures across platforms, dutctl eliminates the fragmentation of device
      management tools that has long plagued firmware workflows.

      The project features remote device control, command streaming,
      multi-architecture testing, and a flexible plugin architecture for
      extensibility.
    '';
    homepage = "https://github.com/BlindspotSoftware/dutctl";
    changelog = "https://github.com/BlindspotSoftware/dutctl/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    mainProgram = "dutctl";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
