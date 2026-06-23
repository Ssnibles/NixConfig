{ lib, ... }:
let
  dir = ./.;
  self = "default.nix";
  entries = builtins.readDir dir;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != self
  ) entries;
  imports = lib.mapAttrsToList (name: _: ./${name}) nixFiles;
in {
  inherit imports;
}
