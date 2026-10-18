# Spotify & Spicetify Application Feature
# Spotify desktop music player configured and customised with Spicetify.
# Uses a hand-written "Vague" theme (modules/features/apps/spicetify-theme)
# that mirrors the active system palette, typography and rounded desktop
# styling, plus useful extensions and custom sidebar apps.
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

          spotifyPackage = lib.mkDefault pkgs.unstable.spotify;

          # Custom theme: a minimal, modern look built around the active
          # palette. `builtins.path` copies the repo directory into the Nix
          # store so it satisfies the theme's `pathInStore` option type.
          theme = lib.mkDefault {
            name = "Vague";
            src = builtins.path {
              path = ./spicetify-theme;
              name = "spicetify-vague";
            };
            # The theme is pure CSS; there is no theme.js to inject.
            injectThemeJs = false;
          };

          # Colour scheme written to color.ini. Spicetify exposes every key as
          # `--spice-<key>` / `--spice-rgb-<key>`, which is what user.css uses.
          customColorScheme = lib.mkDefault {
            # Standard Spicetify keys
            text = c.fg;
            subtext = c.fgMid;
            main = c.bg;
            sidebar = c.bgRaised;
            player = c.bg;
            card = c.bgRaised;
            shadow = c.bg;
            selected-row = c.bgSubtle;
            button = c.accent;
            button-active = c.accent;
            button-disabled = c.fgDim;
            tab-active = c.accent;
            notification = c.teal;
            notification-error = c.red;
            misc = c.bgSubtle;

            # Extended keys used by the custom theme
            accent = c.accent;
            accent-active = c.accent;
            accent-inactive = c.bgSubtle;
            border = c.border;
            border-active = c.accent;
            border-inactive = c.border;
            header = c.fgDim;
            highlight = c.bgSubtle;
            yellow = c.yellow;
            green = c.green;
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

          # `betterLibrary` is intentionally omitted: its extension moves the
          # whole library into the main view and leaves a wrapping
          # "Open in the main view" placeholder in the sidebar, which looks
          # broken. The stock library is used instead.
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
