{ lib, ... }:

{
  imports = import ../../../lib/listModules.nix { inherit lib; } {
    path = ./.;
    exclude = [ "default.nix" "shared.nix" ];
  };
}
