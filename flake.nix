{
  description = "Josh's NixOS Flake";

  # ===========================================================================
  # INPUTS
  # To update a single input:  nix flake lock --update-input <n>
  # To update everything:      nix flake update
  # ===========================================================================
  inputs = {
    # Unstable gives you the freshest packages. Swap to "nixos-25.05" etc.
    # for a stable channel if you want slower, more predictable updates.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      # Pin home-manager to the same nixpkgs as the rest of the system to
      # avoid pulling in a second copy of the package set.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww.url = "git+https://codeberg.org/LGFae/awww.git";
  };

  # ===========================================================================
  # OUTPUTS
  # ===========================================================================
  outputs = { self, nixpkgs, home-manager, zen-browser, awww, ... }@inputs: {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        # Set the platform explicitly so hardware-configuration.nix can use
        # lib.mkDefault without conflicting with this declaration.
        { nixpkgs.hostPlatform = "x86_64-linux"; }

        ./configuration.nix

        # Expose flake inputs as overlays so modules can reference them as packages.
        # Fix: use stdenv.hostPlatform.system — `prev.system` is deprecated and warns.
        {
          nixpkgs.overlays = [
            (final: prev: {
              zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
              awww = awww.packages.${prev.stdenv.hostPlatform.system}.default;
            })
          ];
        }

        # Wire home-manager into the NixOS system build.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true; # Share system nixpkgs (no extra eval)
          home-manager.useUserPackages = true; # Install packages into /etc/profiles

          home-manager.users.josh = import ./home.nix;
        }
      ];
    };

  };
}

