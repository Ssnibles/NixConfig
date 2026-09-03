{ inputs, config, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.desktop
    ];
  };
}
