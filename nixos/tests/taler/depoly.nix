import ../make-test-python.nix (
  { pkgs, lib, ... }:
  {
    name = "Taler Depolymerization Test";
    meta = {
      maintainers = [ ];
    };

    nodes = {
      inherit ((pkgs.callPackage ./common/nodes.nix { inherit lib; }).nodes) depolymerization;
    };

    testScript =
      { nodes, ... }:
      ''
        start_all()
      '';
  }
)
