# =============================================================================
# NixOS Flake Configuration
# =============================================================================
# Multi-host configuration with Disko and Home Manager.
# Optimized with a modular host builder lib pattern.
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
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      # Use the custom host builder
      builder = import ./lib/mkHost.nix { inherit inputs; };
      inherit (builder) mkHost;
    in
    {
      nixosConfigurations = {
        # ── Production hosts (Disko enabled) ─────────────────────────────
        desktop = mkHost {
          hostName = "desktop";
          hasNvidia = true;
        };
        laptop = mkHost {
          hostName = "laptop";
          isLaptop = true;
        };

        # ── Test hosts (Disko disabled) ───────────────────────────────
        desktop-test = mkHost {
          hostName = "desktop";
          hasNvidia = true;
          useDisko = false;
        };
        laptop-test = mkHost {
          hostName = "laptop";
          isLaptop = true;
          useDisko = false;
        };
      };

      # Standalone Disko configs for the install script
      diskoConfigurations = {
        desktop = inputs.disko.lib.diskoConfig {
          system = "x86_64-linux";
          modules = [ ./disko/desktop.nix ];
        };
        laptop = inputs.disko.lib.diskoConfig {
          system = "x86_64-linux";
          modules = [ ./disko/laptop.nix ];
        };
      };
    };
}
