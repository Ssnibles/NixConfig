# Spotify with Spicetify.
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
      c = config.theme.colours;
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

      # NVIDIA's Chromium path blocklists some GPU work and explicit sync is
      # disabled globally for WebKitGTK. Chromium supports explicit sync, so
      # remove that workaround here and force the path used by Helium.
      spotifyPackage =
        if config.features.nvidia.enable then
          pkgs.spotify.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgramShell $out/share/spotify/spotify \
                --add-flags '--ignore-gpu-blocklist --enable-gpu-rasterization --use-gl=angle --use-angle=gl --force-prefers-reduced-motion' \
                --unset __NV_DISABLE_EXPLICIT_SYNC
            '';
          })
        else
          pkgs.spotify;
    in
    {
      imports = [
        inputs.spicetify-nix.nixosModules.default
      ];

      options.features.spotify = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable Spotify with Spicetify.";
        };
      };

      config = lib.mkIf config.features.spotify.enable {
        programs.spicetify = {
          enable = true;
          wayland = lib.mkDefault true;

          spotifyPackage = lib.mkDefault spotifyPackage;

          # Ziro with the active palette. user.css is the vendored upstream
          # stylesheet, recoloured through the --spice-* properties below.
          theme = lib.mkDefault {
            name = "Ziro";
            src = builtins.path {
              path = ./spicetify-theme;
              name = "spicetify-ziro";
            };
            # Pure CSS theme, so there is no theme.js.
            injectThemeJs = false;

            # Ziro leaves Spotify's own gradients and blurred surfaces in
            # place. They repaint the whole window while scrolling, so drop
            # them to keep frame times down on NVIDIA.
            additionalCss = lib.mkDefault ''
              *,
              *::before,
              *::after {
                backdrop-filter: none !important;
                text-shadow: none !important;
              }

              :root,
              .encore-base-set,
              .encore-dark-theme {
                --background-noise: none;
              }

              .Root__main-view,
              .main-entityHeader-container,
              .main-entityHeader-background,
              .main-home-homeHeader,
              .main-nowPlayingBar-nowPlayingBar {
                background-image: none !important;
              }
            '';
          };

          # Colours written to color.ini. Spicetify exposes each key as
          # --spice-<key> and --spice-rgb-<key>, which user.css uses.
          # The mappings follow Ziro's own colour scheme: selected-row is the
          # accent and shadow is the text drawn on top of it.
          customColorScheme = lib.mkDefault {
            text = c.fg;
            subtext = c.fgMid;
            main = c.bg;
            sidebar = c.bg;
            player = c.bg;
            card = c.bgRaised;
            shadow = c.bg;
            selected-row = c.accent;
            button = c.accent;
            button-active = c.accent;
            # Hover backgrounds, borders and the seekbar track.
            button-disabled = c.bgSubtle;
            tab-active = c.accent;
            notification = c.bgRaised;
            notification-error = c.red;
            misc = c.bg;
          };

          enabledExtensions = lib.mkDefault (
            with spicePkgs.extensions;
            [
              hidePodcasts
              shuffle
              playNext
              queueTime
              powerBar
              volumePercentage
              copyToClipboard
              beautifulLyrics
              songStats
            ]
          );

          # betterLibrary is left out. It moves the whole library into the main
          # view and leaves a broken placeholder in the sidebar.
          enabledCustomApps = lib.mkDefault (
            with spicePkgs.apps;
            [
              newReleases
            ]
          );
        };
      };
    };
}
