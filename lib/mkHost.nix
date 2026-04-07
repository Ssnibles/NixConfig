# =============================================================================
# Host Builder Function
# =============================================================================
# Generates a NixOS system configuration with standard modules,
# home-manager integration, and host-specific profiles.
# =============================================================================
{ inputs, ... }:

let
  inherit (inputs.nixpkgs) lib;
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
        inherit
          hostName
          isLaptop
          hasNvidia
          isVM
          useDisko
          ;
        isDesktop = !isLaptop;
      };

      # Stable package set – used only for NVIDIA drivers
      stablePkgs = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      # Inject external flake packages via overlays
      overlays = [
        (_final: _prev: {
          zen-browser = inputs.zen-browser.packages.${system}.default;
          awww = inputs.awww.packages.${system}.default;
        })
      ];
    in
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          stablePkgs
          hostProfile
          user
          ;
      };
      modules =
        [
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
