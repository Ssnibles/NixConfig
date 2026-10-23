# Core system settings.
# Nix, caches, locale, networking, base packages, and maintenance.
{ self, inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # Packages allowed despite deprecation or security warnings.
      permittedInsecure = [ ];
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
      ];

      config = {
        nixpkgs = {
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
            permittedInsecurePackages = permittedInsecure;
          };
          overlays = [
            inputs.millennium.overlays.default
            (_: prev: {
              # Extra channel for packages that need a newer or older release.
              # Also the system default while nixpkgs follows unstable.
              unstable = import inputs.nixpkgs-unstable {
                inherit (prev.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = _: true;
                  permittedInsecurePackages = permittedInsecure;
                };
              };
              # Use pkgs.stable.<pkg> if a package breaks on unstable.
              stable = import inputs.nixpkgs-stable {
                inherit (prev.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = _: true;
                  permittedInsecurePackages = permittedInsecure;
                };
              };
            })
            # nixpkgs builds sesh with Go 1.27, but its mock generation uses
            # mockery 3.8.0, which cannot read the Go 1.27 export data. Build
            # sesh with Go 1.26 until nixpkgs fixes the pairing.
            (_: prev: {
              sesh = prev.sesh.override {
                buildGo127Module = prev.buildGo126Module;
              };
            })
          ];
        };

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # cache.nixos.org is already the default, so only add extra caches.
          substituters = [
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          download-buffer-size = 524288000;
          auto-optimise-store = true;
          # The checkout is usually dirty, so suppress the warning on every command.
          warn-dirty = false;

          # Limit build parallelism so jobs and cores do not oversubscribe the
          # CPU. For one large build, override it on the command line.
          max-jobs = 8;
          cores = 2;

          # Faster cache downloads without waiting too long on a dead cache.
          max-substitution-jobs = 32;
          http-connections = 50;
          connect-timeout = 5;
          stalled-download-timeout = 60;
        };

        # Keep NIXPKGS_ALLOW_UNFREE for nix-shell and other impure commands.
        environment.sessionVariables = {
          NIXPKGS_ALLOW_UNFREE = "1";
        };

        hjem.users.${config.username}.files = {
          ".config/nixpkgs/config.nix" = {
            clobber = true;
            text = ''
              {
                allowUnfree = true;
                allowUnfreePredicate = _: true;
                permittedInsecurePackages = [
                  ${lib.concatMapStringsSep "\n    " (pkg: ''"${pkg}"'') permittedInsecure}
                ];
              }
            '';
          };
        };

        # Local time and locale.
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

        networking = {
          modemmanager.enable = false;
          networkmanager = {
            enable = true;
            wifi.backend = "iwd";
            wifi.powersave = false;
            wifi.macAddress = "stable";
            dns = "systemd-resolved";
          };

          wireless.iwd.settings = {
            General = {
              Country = "NZ";
              EnableNetworkConfiguration = false;
              # Opportunistic Wireless Encryption.
              EnableOWE = true;
            };
          };

          nftables.enable = true;

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
              DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com";
              FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
              DNSSEC = "false";
              DNSOverTLS = "opportunistic";
            };
          };
        };

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          # Probe the path MTU when black holes occur, such as PPPoE.
          "net.ipv4.tcp_mtu_probing" = 1;
        };

        environment.systemPackages = with pkgs; [
          swaybg
          wl-clipboard
          brightnessctl
          playerctl
          grim
          slurp
          wlrctl
          tesseract
          jq
          networkmanagerapplet
          adwaita-icon-theme
          self.packages.${pkgs.stdenv.hostPlatform.system}.html-server
          self.packages.${pkgs.stdenv.hostPlatform.system}.boilerplate
          inputs.ytplay.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        xdg.portal = {
          enable = true;
          # Do not set xdgOpenUsePortal. It sends xdg-open through the portal,
          # which shows a chooser instead of using the configured mimeapps.list.
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        hardware.enableRedistributableFirmware = true;
        services.printing.enable = false;

        programs.nh = {
          enable = true;
          flake = "/home/${config.username}/NixConfig";
          clean.enable = true;
          clean.extraArgs = "--keep-since 30d --keep 3";
        };

        nix.optimise.automatic = true;
        nix.optimise.dates = [ "weekly" ];

        # Let prebuilt binaries that are not packaged in Nix run. This covers
        # Android Studio tools, editor debug adapters, game mods, and uv or
        # cargo installed programs.
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            zstd
            openssl
            curl
            libxml2
            icu
            nss
            nspr
            libGL
            libgbm
            vulkan-loader
            libxkbcommon
            fontconfig
            freetype
          ];
        };

        programs.dconf.enable = true;

        # Add ~/.local/bin to the session PATH for uv, cargo, and pipx tools.
        environment.localBinInPath = true;

        # Firmware updates through fwupdmgr. It is D-Bus activated, so no service
        # runs in the background.
        services.fwupd.enable = true;
      };
    };
}
