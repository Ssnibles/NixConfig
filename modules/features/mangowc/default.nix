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
      imports = [
        inputs.mangowc.nixosModules.mango
      ];

      config = {
        wallpaper-destinations = [ "Pictures/wallpaper" ];

        programs.mango.enable = true;

        system.activationScripts.mango-config = ''
          mkdir -p /home/${config.username}/.config/mango
          chown -R ${config.username}:users /home/${config.username}/.config/mango
          ln -sfn /home/${config.username}/NixConfig/modules/features/mangowc/config.conf /home/${config.username}/.config/mango/config.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/mangowc/binds.conf /home/${config.username}/.config/mango/binds.conf
          chown -h ${config.username}:users /home/${config.username}/.config/mango/config.conf /home/${config.username}/.config/mango/binds.conf
        '';

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mango/colours.conf" = {
              text = ''
                focuscolor = #${accent}
                bordercolor = #${border}
              '';
            };
          };
        };
      };
    };
}
