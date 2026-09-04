# =============================================================================
# System Base Module
# =============================================================================
# Core system settings including Nixpkgs overlays, binary caches, locales,
# timezone, base network configuration, and system maintenance.
# =============================================================================
{ self, inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      # Packages permitted despite upstream deprecation/security warnings
      permittedInsecure = [
        "pnpm-10.29.2"
        "electron-40.10.5"
      ];
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
      ];

      config = {
        # ── Nixpkgs & Overlays ────────────────────────────────────────────────
        nixpkgs = {
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
            permittedInsecurePackages = permittedInsecure;
          };
          overlays = [
            inputs.millennium.overlays.default
            (_: prev: {
              unstable = import inputs.nixpkgs-unstable {
                inherit (prev.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = _: true;
                  permittedInsecurePackages = permittedInsecure;
                };
              };
            })
          ];
        };

        # ── Nix Settings & Binary Caches ────────────────────────────────────
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          download-buffer-size = 524288000;
        };

        # ── Localization & Timezone ──────────────────────────────────────────
        time.timeZone = "Pacific/Auckland";

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

        # ── Networking & Firewall ───────────────────────────────────────────
        networking = {
          networkmanager = {
            enable = true;
            wifi.backend = "iwd";
            wifi.powersave = true;
            wifi.macAddress = "stable";
            dns = "systemd-resolved";
          };

          wireless.iwd.settings.General = {
            Country = "NZ";
            EnableNetworkConfiguration = false;
            # Opportunistic Wireless Encryption (Enhanced Open)
            EnableOWE = true;
          };

          nftables.enable = true;

          firewall = {
            enable = true;
            allowedTCPPorts = [ 53317 ];
            allowedUDPPorts = [ 53317 ];
          };
        };

        # ── DNS Over TLS (systemd-resolved) ─────────────────────────────────
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

        # ── Base System Packages ──────────────────────────────────────────────
        environment.systemPackages = with pkgs; [
          swaybg
          wl-clipboard
          brightnessctl
          playerctl
          grim
          grimblast
          slurp
          networkmanagerapplet
          adwaita-icon-theme
          self.packages.${pkgs.stdenv.hostPlatform.system}.html-server
          self.packages.${pkgs.stdenv.hostPlatform.system}.boilerplate
        ];

        # ── XDG Portals ─────────────────────────────────────────────────────
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        # ── Hardware & Printing ──────────────────────────────────────────────
        hardware.enableRedistributableFirmware = true;
        services.printing.enable = false;

        # ── System Maintenance & Store Optimization ─────────────────────────
        programs.nh = {
          enable = true;
          flake = "/home/${config.username}/NixConfig";
          clean.enable = true;
          clean.extraArgs = "--keep-since 30d --keep 3";
        };

        nix.optimise.automatic = true;
        nix.optimise.dates = [ "03:45" ];
      };
    };
}
