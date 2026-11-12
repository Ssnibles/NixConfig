# Host configurations.
# Each directory under modules/hosts is one host. The option groups and the
# flake outputs are generated from the directory names, so adding a host is
# just a new directory with a configuration.nix.
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

  groupNames = [ "shared" ] ++ hosts;
in
{
  options.nixos.modules = lib.genAttrs groupNames (
    name:
    lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "NixOS module merged into the ${name} configuration.";
    }
  );

  config.flake.nixosConfigurations = lib.genAttrs hosts (
    name:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        config.nixos.modules.shared
        config.nixos.modules.${name}
      ];
    }
  );
}
