# =============================================================================
# NixOS Flake Configuration
# =============================================================================
# Multi-host configuration with Disko for production installs and
# hardware-configuration.nix for safe test rebuilds.
#
# Hosts:
#   - desktop / laptop        : Production  (Disko enabled, wipes disk)
#   - desktop-test / laptop-test : Safe rebuild (Disko disabled)
# =============================================================================
{
  description = "Josh's NixOS Flake - Multi-Host Configuration";

  inputs = {
    # Unstable channel for all packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable channel – used for NVIDIA drivers only
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager follows root nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpaper utility
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

      # Stable package set – used only for NVIDIA drivers
      stablePkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      # Inject external flake packages via overlays
      overlays = [
        (_final: _prev: {
          zen-browser = zen-browser.packages.${system}.default;
          awww = awww.packages.${system}.default;
        })
      ];

      # ── Host builder ─────────────────────────────────────────────────────
      # Builds a nixosSystem with a normalised hostProfile attrset that every
      # module can pattern-match on instead of reading raw booleans.
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
          modules =
            [
              { nixpkgs.overlays = overlays; }
              agenix.nixosModules.default
            ]
            ++ nixpkgs.lib.optional useDisko disko.nixosModules.disko
            ++ nixpkgs.lib.optional useDisko [ ./disko/${hostName}.nix ]
            ++ [
              ./hosts/${hostName}/configuration.nix
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
        # ── Production hosts (Disko enabled) ─────────────────────────────
        desktop = mkHost {
          hostName = "desktop";
          isLaptop = false;
          hasNvidia = true;
        };
        laptop = mkHost {
          hostName = "laptop";
          isLaptop = true;
          hasNvidia = false;
        };

        # ── Test hosts (Disko disabled, uses hardware-configuration.nix) ─
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

      # Standalone Disko configs for the install script
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
