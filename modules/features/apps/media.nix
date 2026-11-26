# Media and document applications.
# imv, Zathura, mpv, and Thunar as the graphical file manager.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.theme.colours;

      # Zathura accepts rgba() but not 8 digit hex. Convert a theme hex
      # triplet and an alpha value to an rgba() string.
      hexByte = pos: hex: lib.fromHexString (builtins.substring (pos * 2) 2 hex);
      rgba =
        alpha: hex:
        "rgba(${toString (hexByte 0 hex)}, ${toString (hexByte 1 hex)}, ${toString (hexByte 2 hex)}, ${builtins.toJSON alpha})";

      # Keep search highlights translucent so the text stays readable.
      highlightAlpha = 0.3;

      # Templates use @name@ placeholders so the raw config stays in files.
      replacements = {
        "@bg@" = c.bg;
        "@bgRaised@" = c.bgRaised;
        "@bgSubtle@" = c.bgSubtle;
        "@border@" = c.border;
        "@fg@" = c.fg;
        "@fgMid@" = c.fgMid;
        "@fgDim@" = c.fgDim;
        "@accent@" = c.accent;
        "@teal@" = c.teal;
        "@purple@" = c.purple;
        "@green@" = c.green;
        "@yellow@" = c.yellow;
        "@red@" = c.red;
        "@orange@" = c.orange;
        "@highlight-yellow@" = rgba highlightAlpha c.yellow;
        "@highlight-orange@" = rgba highlightAlpha c.orange;
      };

      subst =
        file:
        lib.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) (
          builtins.readFile file
        );
    in
    {
      config = {
        environment.systemPackages = with pkgs; [
          zathura
          nicotine-plus
          # tauon
          imv
          (mpv.override {
            scripts = [
              mpvScripts.autoload
              mpvScripts.mpris
              mpvScripts.modernz
              mpvScripts.quality-menu
              mpvScripts.smartskip
              mpvScripts.thumbfast
              mpvScripts.webtorrent-mpv-hook
            ];
          })
          spotatui

          # Thunar also provides org.freedesktop.FileManager1, so apps that ask
          # to reveal a folder open a window instead of waiting for a handler.
          thunar
          thunar-volman
          tumbler
        ];

        # gvfs adds trash, MTP, and network mounts. tumbler makes thumbnails
        # and thunar-volman handles removable media.
        services.gvfs.enable = true;

        # Yazi stays available in the shell.

        hjem.users.${config.username} = {
          files = {
            ".config/mpv/mpv.conf".text = builtins.readFile ./media/mpv.conf;
            ".config/mpv/input.conf".text = builtins.readFile ./media/input.conf;
            ".config/mpv/script-opts/nowplaying.conf".text = builtins.readFile ./media/nowplaying.conf;
            ".config/mpv/script-opts/ytdl_hook.conf".text = builtins.readFile ./media/ytdl_hook.conf;
            ".config/mpv/scripts/nowplaying.lua".text = subst ./media/nowplaying.lua.in;
            ".config/mpv/script-opts/thumbfast.conf".text = builtins.readFile ./media/thumbfast.conf;
            ".config/mpv/script-opts/modernz.conf".text = subst ./media/modernz.conf.in;
            ".config/imv/config".text = builtins.readFile ./media/imv-config;
            ".config/zathura/zathurarc".text = subst ./media/zathurarc.in;
          };
        };
      };
    };
}
