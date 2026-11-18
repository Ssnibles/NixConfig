# Host configurations.
# Each directory under modules/hosts is one host. The flake outputs, the
# hostname and the module group name all come from the directory name, so
# adding a host is just a new directory. install.sh creates one for machines
# that have no committed configuration yet.
#
# Files starting with an underscore are written at install time and are picked
# up automatically when present, so a host directory can be as small as one
# configuration.nix.
{
  config,
  inputs,
  lib,
  ...
}:
let
  hosts = builtins.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && !(lib.hasPrefix "_" name) && !(lib.hasPrefix "." name)
    ) (builtins.readDir ./.)
  );

  # A hostname may not contain an underscore or a dot, but a directory name can.
  toHostName = name: builtins.replaceStrings [ "_" "." ] [ "-" "-" ] name;

  hostFiles = [
    "configuration.nix"
    "_hardware-generated.nix"
    "_installer-options.nix"
  ];

  hostModules =
    name:
    map (file: ./. + "/${name}/${file}") (
      builtins.filter (file: builtins.pathExists (./. + "/${name}/${file}")) hostFiles
    );
in
{
  # Features contribute to flake.nixosModules.shared. Every host imports it.
  config.flake.nixosConfigurations = lib.genAttrs hosts (
    name:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        config.flake.nixosModules.shared
        { networking.hostName = lib.mkDefault (toHostName name); }
      ]
      ++ hostModules name;
    }
  );
}
