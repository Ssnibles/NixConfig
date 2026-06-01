{ lib, ... }:
let
  dir = ./.;
  exclude = [
    "default.nix"
    "shared.nix"
  ];
  entries = builtins.readDir dir;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && !(builtins.elem name exclude)
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
