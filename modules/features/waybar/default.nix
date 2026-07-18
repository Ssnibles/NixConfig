{ self, inputs, ... }:
{
  flake.nixosModules.waybar =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          waybar
        ];

        # Configure hjem for specified users
        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/waybar/config.jsonc".source = ./config/config.jsonc;
            ".config/waybar/style.css".source = ./config/style.css;
            ".config/waybar/power_menu.xml".source = ./config/power_menu.xml;
            ".config/waybar/mediaplayer.py".source = ./config/mediaplayer.py;
            ".config/waybar/icons/meson.build".source = ./config/icons/meson.build;
            ".config/waybar/icons/waybar_icons.gresource.xml".source =
              ./config/icons/waybar_icons.gresource.xml;
            ".config/waybar/icons/waybar-privacy-audio-input-symbolic.svg".source =
              ./config/icons/waybar-privacy-audio-input-symbolic.svg;
            ".config/waybar/icons/waybar-privacy-audio-output-symbolic.svg".source =
              ./config/icons/waybar-privacy-audio-output-symbolic.svg;
            ".config/waybar/icons/waybar-privacy-screen-share-symbolic.svg".source =
              ./config/icons/waybar-privacy-screen-share-symbolic.svg;
          };
        };
      };
    };
}
