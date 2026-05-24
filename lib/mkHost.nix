{ inputs, overlays }:

let
  lib = inputs.nixpkgs.lib;
in
{
  mkHost =
    {
      hostName,
      isLaptop ? false,
      hasNvidia ? false,
      isVM ? false,
      useDisko ? true,
      system ? "x86_64-linux",
      user ? "josh",
    }:
    let
      hostProfile = {
        inherit hostName isLaptop hasNvidia isVM useDisko user;
        isDesktop = !isLaptop;
      };
    in
    lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs hostProfile user; };

      modules = [
        {
          nixpkgs.overlays = overlays;
          networking.hostName = hostName;
        }

        inputs.agenix.nixosModules.default
        ../modules/nixos/common.nix
        ../hosts/${hostName}

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostProfile user; };
            users.${user} = import ../users/${user};
          };
        }
      ]
      ++ lib.optional useDisko inputs.disko.nixosModules.disko
      ++ lib.optional useDisko ../disko/${hostName}.nix
      ++ lib.optional hasNvidia ../modules/nixos/hardware/nvidia.nix;
    };
}
