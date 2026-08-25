# =============================================================================
# Mango Wayland Compositor Feature
# =============================================================================
# Enables Mango Wayland compositor, links config & keybindings, and generates
# theme colors file via Hjem.
# =============================================================================
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
      cfg = config.features.mangowc;
      inherit (config.theme.colors)
        accent
        border
        ;
    in
    {
      imports = [
        inputs.mangowc.nixosModules.mango
      ];

      options.features.mangowc.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable MangoWC Wayland compositor feature.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];

        programs.mango.enable = true;

        system.activationScripts.mango-config = ''
          mkdir -p /home/${config.username}/.config/mango
          chown -R ${config.username}:users /home/${config.username}/.config/mango
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/config.conf /home/${config.username}/.config/mango/config.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/binds.conf /home/${config.username}/.config/mango/binds.conf
        '';

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mango/colours.conf" = {
              text = ''
                focuscolor = 0x${accent}ff
                bordercolor = 0x${border}ff
              '';
            };
            ".config/xdg-desktop-portal-wlr/config" = {
              text = ''
                [screencast]
                chooser_type = simple
                chooser_cmd = ${pkgs.slurp}/bin/slurp -f %o -or
              '';
            };
          };
        };
      };
    };
}
