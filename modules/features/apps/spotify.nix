# =============================================================================
# Spotify & Spicetify Application Feature
# =============================================================================
# Spotify desktop music player configured and customized with Spicetify.
# Includes theme color synchronization with the active system palette
# and popular extensions (adblockify, hidePodcasts, shuffle).
# =============================================================================
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
      c = config.theme.colors;
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

          spotifyPackage = lib.mkDefault pkgs.unstable.spotify;

          # TUI (Terminal UI / text) theme based on spicetify-tui and darkthemer
          theme = lib.mkDefault spicePkgs.themes.text;

          customColorScheme = lib.mkDefault {
            # TUI (text) theme specific color keys
            accent = c.accent;
            accent-active = c.accent;
            accent-inactive = c.bg;
            banner = c.accent;
            border-active = c.accent;
            border-inactive = c.border;
            header = c.fgDim;
            highlight = c.bgSubtle;
            main = c.bg;
            notification = c.teal;
            notification-error = c.red;
            subtext = c.fgMid;
            text = c.fg;

            # Fallback keys for standard themes
            sidebar = c.bgRaised;
            player = c.bg;
            card = c.bgRaised;
            shadow = c.bg;
            selected-row = c.bgSubtle;
            button = c.accent;
            button-active = c.accent;
            button-disabled = c.fgDim;
            tab-active = c.accent;
            misc = c.bgSubtle;
          };

          enabledExtensions = lib.mkDefault (
            with spicePkgs.extensions;
            [
              adblockify
              hidePodcasts
              shuffle
            ]
          );
        };
      };
    };
}
