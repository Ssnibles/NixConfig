{ lib }:

{
  path,
  exclude ? [ "default.nix" ],
  extra ? [ ],
}:
let
  entries = builtins.readDir path;
  nixFiles = lib.filterAttrs (
    name: type:
    type == "regular" && lib.hasSuffix ".nix" name && !(builtins.elem name exclude)
  ) entries;
  nixDirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists (path + "/${name}/default.nix")
  ) entries;
in

lib.mapAttrsToList (name: _: path + "/${name}") nixFiles
++ lib.mapAttrsToList (name: _: path + "/${name}") nixDirs
++ extra
