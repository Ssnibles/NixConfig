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
        hjem.users."${config.username}" = {
          files = {
            ".config/gtk-3.0/settings.ini" = {
              text = ''
                [Settings]
                gtk-cursor-theme-name=Bibata-Modern-Ice
                gtk-cursor-theme-size=24
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
