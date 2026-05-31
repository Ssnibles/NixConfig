{ lib, ... }:
let
  dir = ./.;
  self = "default.nix";
  entries = builtins.readDir dir;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != self
  ) entries;
  nixDirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists (dir + "/${name}/default.nix")
  ) entries;
  imports =
    lib.mapAttrsToList (name: _: ./${name}) nixFiles ++ lib.mapAttrsToList (name: _: ./${name}) nixDirs;
in
{
  inherit imports;
}
