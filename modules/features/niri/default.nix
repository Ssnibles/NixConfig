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
          tesseract
          xwayland-satellite
          inputs.niri-float-sticky.packages.${pkgs.stdenv.hostPlatform.system}.niri-float-sticky
        ];

        system.activationScripts.niri-config = ''
          mkdir -p /home/${config.username}/.config/niri
          chown -R ${config.username}:users /home/${config.username}/.config/niri
          ln -sfn /home/${config.username}/NixConfig/modules/features/niri/config.kdl /home/${config.username}/.config/niri/config.kdl
          chown -h ${config.username}:users /home/${config.username}/.config/niri/config.kdl
        '';
      };
    };
}
