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

          # Theme built from the active palette. builtins.path copies it into
          # the store for the theme's pathInStore option.
          theme = lib.mkDefault {
            name = "Vague";
            src = builtins.path {
              path = ./spicetify-theme;
              name = "spicetify-vague";
            };
            # Pure CSS theme, so there is no theme.js.
            injectThemeJs = false;
          };

          # Colours written to color.ini. Spicetify exposes each key as
          # --spice-<key> and --spice-rgb-<key>, which user.css uses.
          customColorScheme = lib.mkDefault {
            # Standard Spicetify keys.
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

            # Extra keys used by this theme.
            inherit (c)
              accent
              border
              yellow
              green
              ;
            accent-active = c.accent;
            accent-inactive = c.bgSubtle;
            border-active = c.accent;
            border-inactive = c.border;
            header = c.fgDim;
            highlight = c.bgSubtle;
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
