# Desktop Environment Cursors Feature
# Configures Bibata Modern Ice cursor theme for GTK applications, Xcursor, and Hyprcursor.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [ bibata-cursors ];

        environment.sessionVariables = {
          XCURSOR_THEME = "Bibata-Modern-Ice";
          XCURSOR_SIZE = "24";
          HYPRCURSOR_THEME = "Bibata-Modern-Ice";
          HYPRCURSOR_SIZE = "24";
        };

        hjem.users.${config.username} = {
          files = {
            # GTK stores the font DPI in 1/1024ths of a DPI. Minimal Wayland
            # compositors (Mango, etc.) do not provide gtk-xft-dpi, leaving it
            # at -1; WebKitGTK then derives a negative device pixel ratio and
            # collapses every webview's layout. 96 DPI is 96 * 1024 = 98304.
            ".config/gtk-3.0/settings.ini" = {
              text = ''
                [Settings]
                gtk-cursor-theme-name=Bibata-Modern-Ice
                gtk-cursor-theme-size=24
                gtk-xft-dpi=98304
              '';
            };

            ".config/environment.d/cursor.conf" = {
              text = ''
                XCURSOR_THEME=Bibata-Modern-Ice
                XCURSOR_SIZE=24
                HYPRCURSOR_THEME=Bibata-Modern-Ice
                HYPRCURSOR_SIZE=24
              '';
            };
          };
        };
      };
    };
}
