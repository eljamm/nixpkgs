{
  system ? builtins.currentSystem,
  pkgs ? import ../../.. { inherit system; },
}:
{
  basic = import ./tests/basic.nix { inherit system pkgs; };
  online = import ./tests/online.nix { inherit system pkgs; };
}
