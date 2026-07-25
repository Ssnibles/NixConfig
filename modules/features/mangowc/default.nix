{ self, inputs, ... }:
{
  flake.nixosModules.mangowc =
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
        inputs.mangowc.nixosModules.mango
        self.nixosModules.cursors
        self.nixosModules.vicinae
        self.nixosModules.quickshell
        self.nixosModules.wallpapers
      ];

      config = {
        wallpaper-destinations = [ "Pictures/wallpapers" ];

        programs.mango.enable = true;

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
        ];

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        system.activationScripts.mango-config = ''
          mkdir -p /home/${config.username}/.config/mango
          ln -sfn /home/${config.username}/NixConfig/modules/features/mangowc/config.conf /home/${config.username}/.config/mango/config.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/mangowc/binds.conf /home/${config.username}/.config/mango/binds.conf
        '';

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mango/colours.conf".text = ''
              focuscolor = ${accent}
              bordercolor = ${border}
            '';
          };
        };
      };
    };
}
