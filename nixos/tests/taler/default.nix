{
  system ? builtins.currentSystem,
  pkgs ? import ../../.. { inherit system; },
}:
{
  basic = import ./basic.nix { inherit system pkgs; };
  online = import ./online.nix { inherit system pkgs; };
}
