{ lib
, fetchFromGitHub
, callPackage
, rustPlatform
, substituteAll
, openssl
}:

rustPlatform.buildRustPackage {
  pname = "mitm-cache";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "chayleaf";
    repo = "mitm-cache";
    rev = "49c12d99878b86b47a911ebdee9d1f5c4b7a1c95";
    hash = "sha256-wVefXc1jPltITn4CFC1ScZtAx02r0EOIz2VhjgWUWrE=";
  };

  cargoHash = "sha256-7sMtD1EOljiGjnN+sWhGtwx3io81qIIIST8AZRu4NdM=";

  setupHook = substituteAll {
    src = ./setup-hook.sh;
    inherit openssl;
  };

  passthru.fetch = callPackage ./fetch.nix { };

  meta = with lib; {
    description = "A MITM caching proxy for use in nixpkgs";
    license = licenses.mit;
    maintainers = with maintainers; [ chayleaf ];
    mainProgram = "mitm-cache";
  };
}
