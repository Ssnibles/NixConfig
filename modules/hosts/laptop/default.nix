{ inputs, config, ... }:
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.laptop
    ];
  };
}
