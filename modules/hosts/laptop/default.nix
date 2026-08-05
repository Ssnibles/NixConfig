{ inputs, config, ... }:
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.nixos.modules.shared
      config.nixos.modules.laptop
    ];
  };
}
