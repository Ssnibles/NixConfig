# Supported target systems.
{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
  ];

  # Match the NixOS package config so `nix flake check` accepts the unfree
  # font packages built from this repository.
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ ];
        };
      };
    };
}
