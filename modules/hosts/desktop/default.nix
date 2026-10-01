{ inputs, config, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.desktop
    ];
  };
}
