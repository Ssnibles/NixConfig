{ self, inputs, ... }:
{
  flake.nixosModules.base =
    { pkgs, lib, config, ... }:
    {
      imports = [
        inputs.hjem.nixosModules.default
        self.nixosModules.theme
        self.nixosModules.theme-palette
        ../../_options.nix
      ];

      config = {
        username = "josh";

        nixpkgs = {
          config = {
            allowUnfree = true;
            allowInsecure = true;
            permittedInsecurePackages = [
              "pnpm-10.29.2"
              "electron-40.10.5"
            ];
          };
          overlays = [
            inputs.millennium.overlays.default
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                inherit (prev.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  allowInsecure = true;
                  permittedInsecurePackages = [
                    "pnpm-10.29.2"
                    "electron-40.10.5"
                  ];
                };
              };
            })
          ];
        };

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Set your time zone.
        time.timeZone = "Pacific/Auckland";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };

        # Enable networking
        networking.networkmanager.enable = true;

        # Enable the X11 windowing system.
        services.xserver.enable = true;

        # Configure keymap in X11
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        # Enable CUPS to print documents.
        services.printing.enable = false;

        programs.nh = {
          enable = true;
          clean.enable = true;
        };

        # Enable touchpad support (enabled default in most desktopManager).
        # services.xserver.libinput.enable = true;

        # Some programs need SUID wrappers, can be configured further or are
        # started in user sessions.
        # programs.mtr.enable = true;
        # programs.gnupg.agent = {
        #   enable = true;
        #   enableSSHSupport = true;
        # };

        # List services that you want to enable:

        # Optimizations and garbage collection
        nix.optimise.automatic = true;
        nix.optimise.dates = [ "03:45" ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };

    };
}
