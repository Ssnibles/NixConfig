{ self, inputs, ... }:
{
  flake.nixosModules.cli =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          vim
          wget
          git
          ripgrep
          zip
          unzip
          fastfetch
        ];
      };
    };
}
