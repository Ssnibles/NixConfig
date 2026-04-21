# =============================================================================
# NixOS Flake Configuration
# =============================================================================
{
  description = "NixOS Config";

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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qml-language-server = {
      url = "github:cushycush/qml-language-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      # ── Shared Overlays ──────────────────────────────────────────────────────
      # Single definition of overlays used by all configurations.
      overlays = [
        inputs.nur.overlays.default
        (final: prev: {
          # Use unstable channel for specific packages
          unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };

          # Inject inputs into the main package set
          zen-browser = inputs.zen-browser.packages.${system}.default;
          nix-minecraft = inputs.nix-minecraft.legacyPackages.${system};

          # Use unstable for Neovim (fresh but pre-built)
          neovim = final.unstable.neovim;
          neovim-unwrapped = final.unstable.neovim-unwrapped;
        })
      ];

      # Standard pkgs used for standalone HM or logic
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      # Pass pre-computed overlays to the builder
      builder = import ./lib/mkHost.nix { inherit inputs overlays; };
      inherit (builder) mkHost;

      # ── HM Builder ───────────────────────────────────────────────────────────
      mkHome =
        {
          hostName,
          isLaptop ? false,
          hasNvidia ? false,
          user ? "josh",
        }:
        let
          hostProfile = {
            inherit
              hostName
              isLaptop
              hasNvidia
              user
              ;
            isDesktop = !isLaptop;
            isVM = false;
            useDisko = false;
          };
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./users/${user} ];
          extraSpecialArgs = { inherit inputs hostProfile user; };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost {
          hostName = "desktop";
          hasNvidia = true;
        };
        laptop = mkHost {
          hostName = "laptop";
          isLaptop = true;
        };
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
