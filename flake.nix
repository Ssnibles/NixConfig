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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Local development input
    pomodoro = {
      url = "path:/home/josh/pomodoro";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuxedo = {
      url = "github:webstonehq/tuxedo";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
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

    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      overlays = [
        inputs.nur.overlays.default
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };

          zen-browser = inputs.zen-browser.packages.${system}.default;
          nix-minecraft = inputs.nix-minecraft.legacyPackages.${system};
          solaar = inputs.solaar.packages.${system}.default;
          helium-browser = inputs.helium-browser.packages.${system}.default;

          tuxedo = final.rustPlatform.buildRustPackage {
            pname = "tuxedo";
            version = "unstable-2026-06-13";
            src = inputs.tuxedo;
            cargoLock.lockFile = "${inputs.tuxedo}/Cargo.lock";
            doCheck = false;
          };

          neovim = final.unstable.neovim;
          neovim-unwrapped = final.unstable.neovim-unwrapped;
        })
      ];

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = overlays;
      };

      mkProfile = import ./lib/profile.nix;
      inherit (import ./lib/mkHost.nix { inherit inputs overlays; }) mkHost;
      semanticColors = import ./lib/colors.nix;

      mkHome =
        {
          hostName,
          isLaptop ? false,
          hasNvidia ? false,
          user ? "josh",
        }:
        let
          hostProfile = mkProfile {
            inherit
              hostName
              isLaptop
              hasNvidia
              user
              ;
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
              semanticColors
              ;
          };
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

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
