{
  description = "Josh's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww.url = "git+https://codeberg.org/LGFae/awww.git";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      agenix,
      zen-browser,
      awww,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # nixos-25.05 package set for the kernel + NVIDIA driver only.
      # allowUnfree must be set here — this pkgs instance doesn't inherit
      # the nixpkgs.config.allowUnfree setting from configuration.nix.
      stablePkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      overlays = [
        (_: _: {
          zen-browser = zen-browser.packages.${system}.default;
          awww = awww.packages.${system}.default;
        })
      ];

      mkHost =
        {
          hostName,
          isLaptop,
          hasNvidia,
          isVM ? false,
        }:
        let
          hostProfile = {
            inherit
              hostName
              isLaptop
              hasNvidia
              isVM
              ;
            isDesktop = !isLaptop;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs stablePkgs hostProfile; };
          modules = [
            { nixpkgs.overlays = overlays; }
            agenix.nixosModules.default
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs hostProfile; };
                users.josh = import ./home.nix;
              };
            }
          ];
        };

    in
    {
      nixosConfigurations = {
        nixos = mkHost {
          hostName = "nixos";
          isLaptop = false;
          hasNvidia = true;
        };
        # laptop = mkHost { hostName = "laptop"; isLaptop = true; hasNvidia = false; };
      };
    };
}
