# =============================================================================
# NixOS Flake Configuration
# =============================================================================
# Multi-host configuration with Disko for production and hardware-configuration.nix
# for test hosts.
#
# Hosts:
#   - desktop / laptop: Production (Disko enabled, wipes disk)
#   - desktop-test / laptop-test: Safe rebuild (Disko disabled)
# =============================================================================
{
  description = "Josh's NixOS Flake - Multi-Host Configuration";

  inputs = {
    # Unstable channel for all packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable channel for NVIDIA drivers only
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager - follows root nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpaper utility - follows root nixpkgs
    awww = {
      url = "git+https://codeberg.org/LGFae/awww.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

      # Stable packages for NVIDIA drivers
      stablePkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      # Overlays for external packages
      overlays = [
        (_final: _prev: {
          zen-browser = zen-browser.packages.${system}.default;
          awww = awww.packages.${system}.default;
        })
      ];

      # Host builder function
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
            # Apply overlays
            { nixpkgs.overlays = overlays; }
            # Secrets
            agenix.nixosModules.default
            # Disko module (only for production hosts)
          ]
          ++ nixpkgs.lib.optional useDisko disko.nixosModules.disko
          # FIXED: No extra brackets around disko config path
          ++ nixpkgs.lib.optional useDisko [ ./disko/${hostName}.nix ]
          ++ [
            # Host configuration
            ./hosts/${hostName}/configuration.nix
            # Home Manager
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
      nixosConfigurations = {
        # Production hosts (Disko enabled)
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
        # Test hosts (Disko disabled, uses hardware-configuration.nix)
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

      # Standalone Disko configs for install script
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
