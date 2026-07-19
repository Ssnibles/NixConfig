{ self, inputs, ... }:
{
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.desktopConfiguration
    ];
  };
}
