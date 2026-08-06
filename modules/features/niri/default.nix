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
          inputs.niri-float-sticky.packages.${pkgs.stdenv.hostPlatform.system}.niri-float-sticky
          (rustPlatform.buildRustPackage {
            pname = "niri-aspect-lock";
            version = "0.1.0";
            src = ./aspect-lock;
            cargoLock.lockFile = ./aspect-lock/Cargo.lock;
          })
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
          chown -R ${config.username}:users /home/${config.username}/.config/niri
          ln -sfn /home/${config.username}/NixConfig/modules/features/niri/config.kdl /home/${config.username}/.config/niri/config.kdl
          chown -h ${config.username}:users /home/${config.username}/.config/niri/config.kdl
        '';
      };
    };
}
