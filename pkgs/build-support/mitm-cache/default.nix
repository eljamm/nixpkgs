{ lib
, fetchFromGitHub
, callPackage
, rustPlatform
, substituteAll
, openssl
, python3Packages
}:

rustPlatform.buildRustPackage {
  pname = "mitm-cache";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "chayleaf";
    repo = "mitm-cache";
    rev = "0781f7ee8def68887f696c70fe7fd77aa583cb9f";
    hash = "sha256-KlWWB0Eht9meCzKUGrWoyQsn4YI6e1UslOVK8QmKMkY=";
  };

  cargoHash = "sha256-pltVvzX4t1oL06pYaEIaqZ9ki8Vj78lglYRDUdS4mH8=";

  setupHook = substituteAll {
    src = ./setup-hook.sh;
    inherit openssl;
    ephemeral_port_reserve = python3Packages.ephemeral-port-reserve;
  };

  passthru.fetch = callPackage ./fetch.nix { };

  meta = with lib; {
    description = "A MITM caching proxy for use in nixpkgs";
    license = licenses.mit;
    maintainers = with maintainers; [ chayleaf ];
    mainProgram = "mitm-cache";
  };
}
