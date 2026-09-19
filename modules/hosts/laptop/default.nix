{ inputs, config, ... }:
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
    };
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.laptop
    ];
  };
}
