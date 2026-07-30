{ self, inputs, ... }:
{
  flake.nixosModules.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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
              unstable = (import inputs.nixpkgs-unstable {
                inherit (prev.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  allowInsecure = true;
                  permittedInsecurePackages = [
                    "pnpm-10.29.2"
                    "electron-40.10.5"
                  ];
                };
              }).extend (final': prev': {
                qutebrowser = prev'.qutebrowser.overrideAttrs (old: {
                  patches = (old.patches or []) ++ [
                    ../qutebrowser-profile-scripts.patch
                  ];
                });
              });
            })
          ];
        };

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://cache.nixos.org/"
            "https://cache.garnix.io"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.garnix.io:Lf0liRJ2oT5zekG0arzGcHtrIfuVjGrAG1MxRCBuFlA="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          download-buffer-size = 524288000;
        };

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
        networking.nftables.enable = true;

        # DNS resolution via systemd-resolved
        services.resolved.enable = true;

        # Ensure IP forwarding (avoids conflict between Docker and NetworkManager)
        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

        environment.systemPackages = with pkgs; [ nftables ];

        # Enable redistributable firmware (required for AMD GPU firmware)
        hardware.enableRedistributableFirmware = true;

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
