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
          # Some bundles only ship a scalable SVG icon. Qt launchers such as
          # Vicinae need a raster icon, so link the AppStream PNG fallback into
          # the exported hicolor theme.
          install_app_icons() {
            local app_id="$1"
            local app_dir="/var/lib/flatpak/app/$app_id/current/active/files/share/app-info/icons/flatpak"
            local theme_dir="/var/lib/flatpak/exports/share/icons/hicolor"
            local src size changed=0

            [ -d "$app_dir" ] || return 0
            for src in "$app_dir"/*/"$app_id.png"; do
              [ -f "$src" ] || continue
              size="$(basename "$(dirname "$src")")"
              [ -e "$theme_dir/$size/apps/$app_id.png" ] && continue
              mkdir -p "$theme_dir/$size/apps"
              ln -s "$src" "$theme_dir/$size/apps/$app_id.png"
              changed=1
            done

            if [ "$changed" = 1 ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
              gtk-update-icon-cache -f -t "$theme_dir" >/dev/null 2>&1 || true
            fi
          }

          # Install or update a GitHub release bundle. The asset template gets
          # the release tag and the tag without a leading v. An empty checksum
          # asset skips verification.
          install_github_bundle() {
            local app_id="$1" owner="$2" repo="$3" asset_template="$4" sums_asset="$5"
            local state="''${STATE_DIRECTORY:-/var/lib/flatpak-bundles}/$app_id.tag"
            local latest_url tag version asset url tmp expected actual

            latest_url="$(curl -fsSL --retry 3 --connect-timeout 15 -o /dev/null \
              -w '%{url_effective}' "https://github.com/$owner/$repo/releases/latest")" || {
              echo "flatpak-bundles: cannot resolve the latest release of $owner/$repo" >&2
              return 1
            }
            case "$latest_url" in
              */releases/tag/*) tag="''${latest_url##*/}" ;;
              *)
                echo "flatpak-bundles: could not resolve the latest release of $owner/$repo (got $latest_url)" >&2
                return 1
                ;;
            esac

            if [ -f "$state" ] && [ "$(cat "$state")" = "$tag" ]; then
              # Make sure the raster icon exists for installs made by older
              # versions or another tool.
              install_app_icons "$app_id"
              echo "flatpak-bundles: $app_id $tag is already installed"
              return 0
            fi

            version="''${tag#v}"
            asset="''${asset_template//\{tag\}/$tag}"
            asset="''${asset//\{version\}/$version}"
            sums_asset="''${sums_asset//\{tag\}/$tag}"
            sums_asset="''${sums_asset//\{version\}/$version}"
            url="https://github.com/$owner/$repo/releases/download/$tag/$asset"

            tmp="$(mktemp -d)"
            if ! curl -fsSL --retry 3 --connect-timeout 15 -o "$tmp/$asset" "$url"; then
              echo "flatpak-bundles: failed to download $url" >&2
              rm -rf "$tmp"
              return 1
            fi

            if [ -n "$sums_asset" ]; then
              if ! curl -fsSL --retry 3 --connect-timeout 15 \
                -o "$tmp/$sums_asset" \
                "https://github.com/$owner/$repo/releases/download/$tag/$sums_asset"; then
                echo "flatpak-bundles: failed to download $sums_asset for $tag" >&2
                rm -rf "$tmp"
                return 1
              fi
              expected="$(awk -v f="$asset" \
                '{ n = $2; sub(/^\*/, "", n); if (n == f) { print $1; exit } }' \
                "$tmp/$sums_asset")"
              if [ -z "$expected" ]; then
                echo "flatpak-bundles: $sums_asset has no entry for $asset" >&2
                rm -rf "$tmp"
                return 1
              fi
              actual="$(sha256sum "$tmp/$asset" | awk '{ print $1 }')"
              if [ "$expected" != "$actual" ]; then
                echo "flatpak-bundles: checksum mismatch for $asset" >&2
                echo "  expected: $expected" >&2
                echo "  actual:   $actual" >&2
                rm -rf "$tmp"
                return 1
              fi
            fi

            if ! flatpak install --system --noninteractive --or-update -y \
              --bundle "$tmp/$asset"; then
              echo "flatpak-bundles: failed to install $app_id $tag" >&2
              rm -rf "$tmp"
              return 1
            fi

            install_app_icons "$app_id"
            printf '%s\n' "$tag" > "$state"
            rm -rf "$tmp"
            echo "flatpak-bundles: installed $app_id $tag"
          }

          mkdir -p "''${STATE_DIRECTORY:-/var/lib/flatpak-bundles}"
          rc=0
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              _: bundle:
              "install_github_bundle ${
                lib.concatStringsSep " " (
                  map lib.escapeShellArg [
                    bundle.appId
                    bundle.github.owner
                    bundle.github.repo
                    bundle.github.asset
                    (if bundle.github.checksums == null then "" else bundle.github.checksums)
                  ]
                )
              } || rc=1"
            ) cfg.bundles
          )}
          exit "$rc"
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
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  appId = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Application ID of the bundle.";
                  };

                  github = lib.mkOption {
                    type = lib.types.submodule {
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
                            Release asset filename. `{version}` (or `{tag}`) is
                            replaced with the tag of the latest release.
                          '';
                          example = "Nuvio-Linux-x86_64-{version}.flatpak";
                        };
                        checksums = lib.mkOption {
                          type = lib.types.nullOr lib.types.str;
                          default = "SHA256SUMS.txt";
                          description = ''
                            Checksums asset used to verify the downloaded
                            bundle. Set to null to skip verification (not
                            recommended).
                          '';
                        };
                      };
                    };
                    description = ''
                      Install this bundle from the latest GitHub release. The
                      tag, asset name and checksum are resolved when the
                      install service runs; nothing is pinned in Nix.
                    '';
                  };
                };
              }
            )
          );
          default = { };
          description = ''
            GitHub-release Flatpak bundles to install and keep at the latest
            upstream release.
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
          "com.nuvio.media.desktop".github = {
            owner = "NuvioMedia";
            repo = "NuvioDesktop";
            asset = "Nuvio-Linux-x86_64-{version}.flatpak";
          };

          # Spotifast is also a GitHub release bundle. Its tag starts with v,
          # so the asset name uses the full tag.
          "rocks.spotifast.Spotifast".github = {
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

        # The auto-update timer can run before the network is ready and log a
        # failed lookup. Wait for multi-user and network-online instead.
        systemd.services."flatpak-managed-install-timer" = {
          after = [
            "multi-user.target"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
        };
        systemd.services."flatpak-managed-install".wants = [ "network-online.target" ];

        # Install or update the bundles in features.flatpak.bundles. Start after
        # the nix-flatpak installer so a bundle that used to be in packages is
        # not removed and reinstalled at the same time.
        systemd.services."flatpak-bundles" = lib.mkIf (cfg.bundles != { }) {
          description = "Install/update Flatpak bundles from upstream GitHub releases";
          wantedBy = [ "default.target" ];
          wants = [
            "network-online.target"
            "flatpak-managed-install.service"
          ];
          after = [
            "multi-user.target"
            "network-online.target"
            "flatpak-managed-install.service"
          ];
          unitConfig = {
            # Limit retries for a broken asset or checksum. The daily timer is
            # the final retry.
            StartLimitIntervalSec = "1h";
            StartLimitBurst = 3;
          };
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "flatpak-bundles";
            ExecStart = lib.getExe bundleInstaller;
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
