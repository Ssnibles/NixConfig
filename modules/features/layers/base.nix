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

        networking = {
          networkmanager = {
            enable = true;
            wifi.backend = "iwd";
            wifi.powersave = false;
            wifi.macAddress = "stable";
            dns = "systemd-resolved";
          };
          wireless.iwd.settings.General = {
            Country = "NZ";
            EnableNetworkConfiguration = false;
            # Opportunistic Wireless Encryption (Enhanced Open). iwd randomizes
            # the MAC address itself when connecting to OWE networks.
            EnableOWE = true;
          };

          firewall = {
            enable = true;
            allowedTCPPorts = [ 53317 ];
            allowedUDPPorts = [ 53317 ];
          };
        };

        services.resolved = {
          enable = true;
          settings = {
            Resolve = {
              DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111";
              FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
              DNSSEC = "allow-downgrade";
              DNSOverTLS = "opportunistic";
              Domains = [ "~." ];
            };
          };
        };

        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

        environment.systemPackages = with pkgs; [ iwd ];

        # Enable redistributable firmware (required for AMD GPU firmware)
        hardware.enableRedistributableFirmware = true;

        # Enable CUPS to print documents.
        services.printing.enable = false;

        programs.nh = {
          enable = true;
          clean.enable = true;
        };

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
