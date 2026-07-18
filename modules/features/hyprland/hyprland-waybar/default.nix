{ self, inputs, ... }:
{
  flake.nixosModules.hyprland =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        self.nixosModules.cursors
        self.nixosModules.waybar
        self.nixosModules.wallpapers
      ];

      config = {
        wallpaper-destinations = [ "Pictures/wallpapers" ];
        # System-level configuration
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          waybar
          hyprpaper
          wofi
          kitty
          firefox
          wl-clipboard
          brightnessctl
          playerctl
          grim
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
          gnome-keyring
          seahorse
          flameshot
        ];

        services.gnome.gnome-keyring.enable = true;
        services.dbus.packages = [
          pkgs.gnome-keyring
          pkgs.gcr
        ];
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
            ".config/hypr/hyprland.conf".source = ./hyprland.conf;
            ".config/hypr/hyprpaper.conf".source = ./hyprpaper.conf;
          };
        };
      };
    };
}
