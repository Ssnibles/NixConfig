# =============================================================================
# Host Builder Function
# =============================================================================
# Generates a NixOS system configuration. Overlays and inputs are defined
# in flake.nix and passed here.
# =============================================================================
{ inputs, overlays, ... }:

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
        inherit
          hostName
          isLaptop
          hasNvidia
          isVM
          useDisko
          user
          ;
        isDesktop = !isLaptop;
      };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      # Pass core arguments to all modules
      specialArgs = { inherit inputs hostProfile user; };

      modules = [
        {
          nixpkgs.overlays = overlays;
          networking.hostName = hostName;
        }

        # Core modules
        inputs.agenix.nixosModules.default
        ../modules/nixos/common.nix
        ../hosts/${hostName}

        # Integrated Home Manager
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
      # Conditional hardware/service modules
      ++ inputs.nixpkgs.lib.optional useDisko inputs.disko.nixosModules.disko
      ++ inputs.nixpkgs.lib.optional useDisko ../disko/${hostName}.nix
      ++ inputs.nixpkgs.lib.optional hasNvidia ../modules/nixos/hardware/nvidia.nix;
    };
}
