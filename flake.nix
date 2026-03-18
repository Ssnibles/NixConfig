# =============================================================================
# NixOS Flake Configuration
# =============================================================================
# This file defines the entire system topology, inputs, and host configurations.
# It supports multiple hosts (desktop, laptop) with shared modules and host-specific
# overrides.
#
# Testing Strategy:
#   - Use 'desktop' or 'laptop' for production installs (includes Disko).
#   - Use 'desktop-test' or 'laptop-test' for safe rebuilding (excludes Disko).
# =============================================================================
{
  description = "Josh's NixOS Flake - Multi-Host Configuration";

  inputs = {
    # Unstable channel for latest packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable channel for kernel/drivers (used by NVIDIA module)
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # User environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management (age encryption)
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom browser flake
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpaper utility
    awww.url = "git+https://codeberg.org/LGFae/awww.git";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      agenix,
      disko,
      zen-browser,
      awww,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # Import stable pkgs for drivers/kernel that require stability
      stablePkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      # Custom overlays for external packages
      overlays = [
        (_: _: {
          zen-browser = zen-browser.packages.${system}.default;
          awww = awww.packages.${system}.default;
        })
      ];

      # Host builder function
      # Arguments:
      #   hostName: Identifier for the host (e.g., "desktop")
      #   isLaptop: Boolean for power management differences
      #   hasNvidia: Boolean for driver selection
      #   isVM: Boolean for virtualization tweaks
      #   useDisko: Boolean to include Disko module (false for testing)
      mkHost =
        {
          hostName,
          isLaptop,
          hasNvidia,
          isVM ? false,
          useDisko ? true,
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
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs stablePkgs hostProfile; };
          modules = [
            # Apply overlays to pkgs
            { nixpkgs.overlays = overlays; }

            # Secrets module
            agenix.nixosModules.default

            # Conditionally include Disko module
            # When useDisko is false, hardware-configuration.nix handles mounts
          ]
          ++ nixpkgs.lib.optional useDisko disko.nixosModules.disko
          ++ nixpkgs.lib.optional useDisko [ ./disko/${hostName}.nix ]
          ++ [
            # Host-specific system configuration
            ./hosts/${hostName}/configuration.nix

            # Home Manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs hostProfile; };
                users.josh = import ./users/josh/home.nix;
              };
            }
          ];
        };
    in
    {
      # Production configurations (Disko enabled)
      nixosConfigurations = {
        desktop = mkHost {
          hostName = "desktop";
          isLaptop = false;
          hasNvidia = true;
          useDisko = true;
        };
        laptop = mkHost {
          hostName = "laptop";
          isLaptop = true;
          hasNvidia = false;
          useDisko = true;
        };

        # Test configurations (Disko disabled for safe rebuilding)
        # Use these to test config changes without touching disk partitions
        desktop-test = mkHost {
          hostName = "desktop";
          isLaptop = false;
          hasNvidia = true;
          useDisko = false;
        };
        laptop-test = mkHost {
          hostName = "laptop";
          isLaptop = true;
          hasNvidia = false;
          useDisko = false;
        };
      };

      # Disko standalone configurations for installation script
      diskoConfigurations = {
        desktop = disko.lib.diskoConfig {
          inherit system;
          modules = [ ./disko/desktop.nix ];
        };
        laptop = disko.lib.diskoConfig {
          inherit system;
          modules = [ ./disko/laptop.nix ];
        };
      };
    };
}
