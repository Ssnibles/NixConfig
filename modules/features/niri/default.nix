{ self, inputs, ... }:
{
  flake.nixosModules.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.theme.colors)
        bg
        bgRaised
        bgSubtle
        border
        fg
        fgMid
        fgDim
        accent
        teal
        purple
        green
        yellow
        red
        orange
        ;
    in
    {
      imports = [
        self.nixosModules.cursors
        self.nixosModules.vicinae
        self.nixosModules.quickshell
        self.nixosModules.wallpapers
      ];

      config = {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.niri.enable = true;

        environment.systemPackages = with pkgs; [
          swaybg
          wl-clipboard
          brightnessctl
          playerctl
          grim
          grimblast
          slurp
          libnotify
          networkmanagerapplet
          adwaita-icon-theme
          xwayland-satellite
        ];

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        system.activationScripts.niri-config = ''
          mkdir -p /home/${config.username}/.config/niri
          ln -sfn /home/${config.username}/NixConfig/modules/features/niri/config.kdl /home/${config.username}/.config/niri/config.kdl
        '';
      };
    };
}
