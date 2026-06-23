{ lib, ... }:

{
  imports = import ../../../lib/listModules.nix { inherit lib; } { path = ./.; };
}
