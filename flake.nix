{
  description = "Josh's NixOS Flake";

  # ===========================================================================
  # INPUTS
  # To update a single input:  nix flake lock --update-input <n>
  # To update everything:      nix flake update
  # ===========================================================================
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww.url = "git+https://codeberg.org/LGFae/awww.git";

    # agenix for secret management
    agenix.url = "github:ryantm/agenix";
  };

  # ===========================================================================
  # OUTPUTS
  # ===========================================================================
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      zen-browser,
      awww,
      agenix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # =========================================================================
      # OVERLAYS
      # Expose flake inputs as packages so home.nix / modules can use them
      # the same way they use anything else from nixpkgs.
      # =========================================================================
      overlays = [
        (final: prev: {
          zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
          awww = awww.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];

      # =========================================================================
      # mkHost — build a NixOS system from an explicit host profile.
      #
      # hostProfile fields:
      #   hostName  string  — the machine's hostname
      #   isLaptop  bool    — true for laptops, false for desktops
      #   hasNvidia bool    — true if the machine has an Nvidia GPU
      #   isVM      bool    — true for VMs / containers (disables hw tuning)
      #
      # isDesktop is derived automatically as !isLaptop so you never have to
      # keep two booleans in sync.
      #
      # Why explicit declarations instead of builtins.pathExists detection?
      # builtins.pathExists is evaluated on the *building* machine, not the
      # target. If you build your laptop config on your desktop (or in the
      # installer ISO), /sys/class/power_supply/BAT0 won't exist there, so
      # isLaptop silently becomes false and the laptop gets the desktop package
      # set (Steam, Lutris, etc.). Explicit declarations are evaluated once,
      # are always correct, and are easy to read in version control.
      # =========================================================================
      mkHost =
        hostProfile:
        let
          # Derive isDesktop so callers only need to set one field.
          profile = hostProfile // {
            isDesktop = !hostProfile.isLaptop;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            hostProfile = profile;
          };
          modules = [
            ./configuration.nix
            agenix.nixosModules.default
            { nixpkgs.overlays = overlays; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                hostProfile = profile;
              };
              home-manager.users.josh = import ./home.nix;
            }
          ];
        };

    in
    {
      nixosConfigurations = {

        # -----------------------------------------------------------------------
        # DESKTOP — main machine, Nvidia GPU, no battery
        # -----------------------------------------------------------------------
        nixos = mkHost {
          hostName = "nixos";
          isLaptop = true;
          hasNvidia = false;
          isVM = false;
        };

        # -----------------------------------------------------------------------
        # Add more hosts here as needed, e.g.:
        # laptop = mkHost {
        #   hostName  = "laptop";
        #   isLaptop  = true;
        #   hasNvidia = false;
        #   isVM      = false;
        # };
        # Then rebuild with: nixos-rebuild switch --flake ~/NixConfig#laptop
        # -----------------------------------------------------------------------

      };
    };
}
