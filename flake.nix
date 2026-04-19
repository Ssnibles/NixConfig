# =============================================================================
# NixOS Flake Configuration
# =============================================================================
# Production-grade multi-host NixOS configuration with the following features:
#   • Dual-channel package management (stable system + unstable user packages)
#   • Declarative disk partitioning via Disko
#   • Secrets management via Agenix
#   • Home Manager integration for user environments
#   • Conditional NVIDIA support
#   • Laptop-specific power management (TLP)
#   • Custom host builder abstraction (lib/mkHost.nix)
#
# Architecture:
#   flake.nix (inputs/outputs) → lib/mkHost.nix (host builder)
#     → modules/nixos/* (system config) + modules/home/* (user config)
#     → hosts/<name>/* (host-specific overrides)
# =============================================================================
{
  description = "Josh's NixOS Configuration - Multi-host flake with Hyprland, Neovim, and Home Manager";

  # ── Nix Configuration ──────────────────────────────────────────────────────
  # Binary cache settings applied to all consumers of this flake
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # ── Core Channels ────────────────────────────────────────────────────────
    # Stable channel: NixOS modules, system services, kernel, drivers
    # Version: 25.11 provides stability for system-level components
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable channel: Latest user-facing packages (apps, CLI tools, dev tools)
    # Overlaid as "unstable" namespace to avoid conflicts with stable packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # ── User Environment ─────────────────────────────────────────────────────
    # Home Manager: Declarative user configuration (dotfiles, packages, services)
    # Follows stable nixpkgs to ensure module API compatibility
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nvf: Neovim configuration framework (Home Manager module)
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim Nightly overlay (replaces pkgs.neovim with nightly builds)
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix: Shared theming framework for Home Manager / NixOS targets
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Infrastructure Tools ─────────────────────────────────────────────────
    # Agenix: Age-based secrets management (encrypted with SSH/age keys)
    # Used for: Spotify credentials, API tokens, etc.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko: Declarative disk partitioning for automated installations
    # Enables reproducible filesystem layouts across reinstalls
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-minecraft: Minecraft packaging helpers (modpacks, servers, tooling)
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser: Privacy-focused browser with modern UI
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    # Spicetify module + package set for Spotify theming/customization
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qml-language-server = {
      url = "github:cushycush/qml-language-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen-nvim = {
      url = "github:ssnibles/matugen.nvim";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      # ── Host Builder ─────────────────────────────────────────────────────
      # Custom abstraction that eliminates boilerplate for each host config
      # See lib/mkHost.nix for implementation details
      builder = import ./lib/mkHost.nix { inherit inputs; };
      inherit (builder) mkHost;
      system = "x86_64-linux";

      # ── Shared package set for standalone Home Manager configs ────────────
      # Mirrors mkHost overlay behavior so `nh home switch` uses the same
      # package universe as the integrated NixOS + Home Manager setup.
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      nightlyNeovim = inputs.neovim-nightly-overlay.packages.${system}.default;

      overlays = [
        (_final: _prev: {
          # Keep nightly Neovim, but avoid replacing vimPlugins with the nightly
          # overlay plugin set (that can force local plugin builds/checks).
          neovim = nightlyNeovim;
          neovim-unwrapped = nightlyNeovim;
          zen-browser = inputs.zen-browser.packages.${system}.default;
          helium = inputs.helium.packages.${system}.default;
          nix-minecraft = inputs.nix-minecraft.legacyPackages.${system};
          unstable = unstablePkgs;
        })
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      mkHome =
        {
          hostName,
          isLaptop ? false,
          hasNvidia ? false,
          isVM ? false,
          useDisko ? true,
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
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./users/${user} ];
          extraSpecialArgs = {
            inherit
              inputs
              hostProfile
              user
              ;
          };
        };

      # ── NixOS System Configurations ──────────────────────────────────────
      # Each host has both a production config (Disko enabled) and a test
      # config (Disko disabled) for safe rebuilds without repartitioning
      nixosConfigurations = {
        # Production: Desktop (AMD CPU + NVIDIA GPU)
        desktop = mkHost {
          hostName = "desktop";
          hasNvidia = true; # Enables nvidia.nix module, stable kernel
        };

        # Production: Laptop (AMD CPU + integrated graphics)
        laptop = mkHost {
          hostName = "laptop";
          isLaptop = true; # Enables TLP, battery optimizations, lid handling
        };

        # Test: Desktop (safe rebuilds, no disk repartitioning)
        desktop-test = mkHost {
          hostName = "desktop";
          hasNvidia = true;
          useDisko = false; # Skips disko module inclusion
        };

        # Test: Laptop (safe rebuilds, no disk repartitioning)
        laptop-test = mkHost {
          hostName = "laptop";
          isLaptop = true;
          useDisko = false;
        };
      };

      # ── Home Manager Configurations ──────────────────────────────────────
      # Expose HM configs directly so `nh home switch` works without a full
      # system rebuild for user-level modules (Hyprland, SwayNC, Neovim, etc.).
      homeConfigurations = {
        "josh@desktop" = mkHome {
          hostName = "desktop";
          hasNvidia = true;
        };
        "josh@laptop" = mkHome {
          hostName = "laptop";
          isLaptop = true;
        };
      };
    in
    {
      inherit
        nixosConfigurations
        homeConfigurations
        ;

      # ── Disko Configurations ─────────────────────────────────────────────
      # Standalone disk layouts for the install.sh bootstrap script
      # These are NOT included in test configs (useDisko = false)
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
