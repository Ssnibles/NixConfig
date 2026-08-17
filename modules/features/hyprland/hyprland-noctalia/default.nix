{ self, ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        # System-level configuration
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          hyprpaper
          hyprshot
          foot
          firefox
          wl-clipboard
          brightnessctl
          playerctl
          grim
          seahorse
          libnotify
          networkmanagerapplet
          adwaita-icon-theme
          self.packages."${pkgs.stdenv.hostPlatform.system}".myNoctalia
        ];

        # gnome-keyring already enabled in shared.nix; seahorse.enable registers dbus packages
        programs.seahorse.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-hyprland
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        # Configure hjem for specified users
        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/hypr/hyprland.lua" = {
              source = ./hyprland.lua;
            };
            ".config/hypr/generated.lua" = {
              source = ./generated.lua;
            };
          };
        };
      };
    };
}
