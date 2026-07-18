{ self, inputs, ... }:
{
  flake.nixosModules.hyprland-noctalia =
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
        wallpaper-destinations = [ "Pictures/Wallpapers" ];
        # System-level configuration
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          waybar
          hyprpaper
          hyprshot
          wofi
          kitty
          firefox
          wl-clipboard
          brightnessctl
          playerctl
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
          gnome-keyring
          grim
          seahorse
          flameshot
          self.packages."${pkgs.stdenv.hostPlatform.system}".myNoctalia
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
          files = let
            confContents = pkgs.writeText "hyprland.conf" ("exec-once = noctalia-shell\n" + (builtins.readFile ./hyprland.conf));
          in {
            ".config/hypr/hyprland.conf".source = confContents;
          };
        };
      };
    };
}
