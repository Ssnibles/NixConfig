{ inputs, config, ... }:
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      # inherit inputs;
      inputs = inputs // {
        mangowc = inputs.mangowc-local;
      };
    };
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.laptop
    ];
  };
}
