{ inputs, overlays }:

let
  lib = inputs.nixpkgs.lib;
  mkProfile = import ./profile.nix;
in
{
  mkHost =
    args:
    let
      hostProfile = mkProfile args;
      hostName = hostProfile.hostName;
      user = hostProfile.user;
      system = args.system or "x86_64-linux";
    in
    lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs hostProfile user;
        semanticColors = import ./colors.nix;
      };

      modules = [
        {
          nixpkgs.overlays = overlays;
          networking.hostName = hostName;
        }

        inputs.agenix.nixosModules.default
        inputs.stylix.nixosModules.stylix
        ../modules/nixos
        ../hosts/${hostName}

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs hostProfile user;
              semanticColors = import ./colors.nix;
            };
            users.${user} = import ../users/${user};
          };
        }
      ]
      ++ lib.optional hostProfile.useDisko inputs.disko.nixosModules.disko
      ++ lib.optional hostProfile.useDisko ../disko/${hostName}.nix;
    };
}
