{ inputs, config, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inputs = inputs // {
        mangowc = inputs.mangowc-local;
      };
    };
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.desktop
    ];
  };
}
