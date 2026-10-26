# Flatpak support.
# Flathub apps are listed by application ID. Apps that are only published as
# GitHub release bundles are downloaded at activation and checked against the
# release checksums.
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.flatpak;

      bundleArgs = lib.concatMap (
        appId:
        let
          bundle = cfg.bundles.${appId};
        in
        [
          appId
          bundle.owner
          bundle.repo
          bundle.asset
          (if bundle.checksums == null then "" else bundle.checksums)
        ]
      ) (lib.attrNames cfg.bundles);

      bundleInstaller = pkgs.writeShellApplication {
        name = "flatpak-bundles";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          flatpak
          gawk
          gtk3
        ];
        text = ''
          ${builtins.readFile ./bundles.sh}

          main ${lib.concatMapStringsSep " " lib.escapeShellArg bundleArgs}
        '';
      };
    in
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      options.features.flatpak = {
        enable = lib.mkEnableOption "Flatpak with the Flathub remote and a declarative app set";

        packages = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
          default = [ ];
          apply = lib.unique;
          description = ''
            Flatpak applications installed from a configured remote. Entries
            are passed straight through to `services.flatpak.packages`, so a
            plain application ID is enough for a Flathub app.
          '';
          example = [
            "org.vinegarhq.Sober"
            "com.spotify.Client"
          ];
        };

        bundles = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                owner = lib.mkOption {
                  type = lib.types.str;
                  description = "GitHub repository owner.";
                };

                repo = lib.mkOption {
                  type = lib.types.str;
                  description = "GitHub repository name.";
                };

                asset = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Release asset filename. `{tag}` is replaced with the release
                    tag and `{version}` with the tag minus a leading `v`.
                  '';
                  example = "Nuvio-Linux-x86_64-{version}.flatpak";
                };

                checksums = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = "SHA256SUMS.txt";
                  description = ''
                    Checksums asset used to verify the downloaded bundle. It
                    accepts the same `{tag}` and `{version}` templates as
                    `asset`. Set to null to skip verification, which is not
                    recommended.
                  '';
                };
              };
            }
          );
          default = { };
          description = ''
            GitHub-release Flatpak bundles to install and keep at the latest
            upstream release, keyed by application ID.
          '';
        };

        overrides = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.attrsOf (
              lib.types.attrsOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str))
            )
          );
          default = { };
          description = ''
            Per-app Flatpak overrides, merged into `services.flatpak.overrides`.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            # Bundles are kept outside the nix-flatpak state. With
            # uninstallUnmanaged enabled, nix-flatpak would remove them on every
            # activation before this service reinstalls them.
            assertion = cfg.bundles == { } || !config.services.flatpak.uninstallUnmanaged;
            message = ''
              features.flatpak.bundles requires services.flatpak.uninstallUnmanaged
              to stay false, otherwise nix-flatpak removes the tracked bundles on
              every activation.
            '';
          }
        ];

        # Hosts can append to these lists. Use lib.mkForce to replace a set.
        features.flatpak.packages = [
          # Community Roblox client, sandboxed by Flatpak.
          "org.vinegarhq.Sober"
          "app.twintaillauncher.ttl"
        ];

        features.flatpak.bundles = {
          # Nuvio Desktop is not on Flathub, so track its latest GitHub release.
          "com.nuvio.media.desktop" = {
            owner = "NuvioMedia";
            repo = "NuvioDesktop";
            asset = "Nuvio-Linux-x86_64-{version}.flatpak";
          };

          # Spotifast is also a GitHub release bundle. Its tag starts with v,
          # so the asset name uses the full tag.
          "rocks.spotifast.Spotifast" = {
            owner = "crmne";
            repo = "spotifast";
            asset = "spotifast-{tag}-x86_64.flatpak";
            checksums = "checksums.txt";
          };
        };

        features.flatpak.overrides = {
          # Flatpak apps do not inherit session variables. Twintail Launcher
          # sets WEBKIT_DISABLE_COMPOSITING_MODE on NVIDIA, which forces CPU
          # rendering and makes the window slow. Skip its NVIDIA fixes, then
          # apply only the DMA-BUF workaround, and use the Wayland socket.
          # If the window misbehaves on Wayland, remove Context.sockets. If it
          # renders blank, also remove WEBKIT_DISABLE_DMABUF_RENDERER.
          "app.twintaillauncher.ttl" = {
            Context.sockets = [ "wayland" ];
            Environment = {
              TTL_BYPASS_NVIDIA_FIXES = "1";
              WEBKIT_DISABLE_DMABUF_RENDERER = "1";
            };
          };
        };

        services.flatpak = {
          # The portal is enabled in base.nix, which satisfies the Flatpak
          # module assertion.
          enable = true;

          remotes = [
            {
              name = "flathub";
              location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];

          # Sober must track the live Roblox version, so update remote apps
          # daily. The bundle timer below does the same for GitHub releases.
          update.auto = {
            enable = true;
            onCalendar = "daily";
          };

          inherit (cfg) packages overrides;
        };

        # Install or update the bundles in features.flatpak.bundles. Start after
        # the nix-flatpak installer so a bundle that used to be in packages is
        # not removed and reinstalled at the same time.
        systemd.services."flatpak-bundles" = lib.mkIf (cfg.bundles != { }) {
          description = "Install or update Flatpak bundles from GitHub releases";
          wantedBy = [ "default.target" ];
          wants = [ "flatpak-managed-install.service" ];
          after = [ "flatpak-managed-install.service" ];
          unitConfig = {
            # Limit retries for a broken asset or checksum. The daily timer is
            # the final retry.
            StartLimitIntervalSec = "1h";
            StartLimitBurst = 3;
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe bundleInstaller;
            StateDirectory = "flatpak-bundles";
            PrivateTmp = true;
            Restart = "on-failure";
            RestartSec = "5min";
          };
        };

        systemd.timers."flatpak-bundles" = lib.mkIf (cfg.bundles != { }) {
          description = "Daily check for new Flatpak bundle releases";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
    };
}
