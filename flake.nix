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
  };

  # ===========================================================================
  # OUTPUTS
  # ===========================================================================
  outputs = { self, nixpkgs, home-manager, zen-browser, awww, ... }@inputs:
    let
      system = "x86_64-linux";

      # -------------------------------------------------------------------------
      # Hardware detection — evaluated once here at flake level.
      #
      # home-manager runs in its own module system and cannot see NixOS
      # config.hostProfile. Instead we run the same builtins.pathExists checks
      # here (pure /sys reads, available during nixos-rebuild) and pass the
      # results into both NixOS and home-manager via specialArgs /
      # extraSpecialArgs so every module shares one set of values without
      # duplication. The host-profile.nix NixOS module still defines the options
      # (allowing manual overrides in configuration.nix), but its defaults also
      # come from these same checks so everything stays consistent.
      # -------------------------------------------------------------------------
      hasBat = name: builtins.pathExists "/sys/class/power_supply/${name}/capacity";
      isLaptop = hasBat "BAT0" || hasBat "BAT1";
      isDesktop = !isLaptop;

      pciBase = "/sys/bus/pci/devices";
      pciDevices =
        if builtins.pathExists pciBase
        then builtins.attrNames (builtins.readDir pciBase)
        else [ ];
      readVendor = dev:
        let r = builtins.tryEval (builtins.readFile "${pciBase}/${dev}/vendor");
        in if r.success then r.value else "";
      hasNvidia = builtins.any
        (dev: nixpkgs.lib.hasPrefix "0x10de"
          (nixpkgs.lib.trim (readVendor dev)))
        pciDevices;

      # Collected into a single attrset so both specialArgs blocks stay tidy.
      hostProfile = { inherit isLaptop isDesktop hasNvidia; };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostProfile; };

        modules = [
          ./configuration.nix

          # Expose flake inputs as packages via overlays.
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Pass the same hostProfile values into home.nix so it can branch
            # on laptop/desktop without re-detecting or touching NixOS config.
            home-manager.extraSpecialArgs = { inherit inputs hostProfile; };

            home-manager.users.josh = import ./home.nix;
          }
        ];
      };
    };
}
