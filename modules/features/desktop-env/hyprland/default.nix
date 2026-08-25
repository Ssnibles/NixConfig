{ self, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.hyprland;
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
      options.features.hyprland.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland Wayland compositor feature.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          hyprpaper
          hyprshot
          seahorse
        ];

        programs.seahorse.enable = true;

        environment.sessionVariables = {
          QS_BAR = "hyprland";
          XDG_CURRENT_DESKTOP = "Hyprland";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
          ];
          config.hyprland = {
            default = [ "hyprland" "gtk" ];
            "org.freedesktop.impl.portal.Screencast" = "hyprland";
            "org.freedesktop.impl.portal.Screenshot" = "hyprland";
          };
        };

        system.activationScripts.hyprland-config = ''
          mkdir -p /home/${config.username}/.config/hypr
          chown -R ${config.username}:users /home/${config.username}/.config/hypr
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/hyprland/hyprland.lua /home/${config.username}/.config/hypr/hyprland.lua
          chown -h ${config.username}:users /home/${config.username}/.config/hypr/hyprland.lua
        '';

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/hypr/hyprland.lua" = {
              source = ./hyprland.lua;
              clobber = true;
            };
            ".config/hypr/generated.lua" = {
              text = ''
                local M = {}

                M.bg = "${bg}"
                M.bgRaised = "${bgRaised}"
                M.bgSubtle = "${bgSubtle}"
                M.border = "${border}"
                M.fg = "${fg}"
                M.fgMid = "${fgMid}"
                M.fgDim = "${fgDim}"
                M.accent = "${accent}"
                M.teal = "${teal}"
                M.purple = "${purple}"
                M.green = "${green}"
                M.yellow = "${yellow}"
                M.red = "${red}"
                M.orange = "${orange}"
                M.accent_hash = "#${accent}"
                M.border_hash = "#${border}"
                M.isDesktop = true
                M.isLaptop = false
                M.wallpaper = "~/Pictures/wallpaper"
                M.screenshot_dir = "~/Pictures/Screenshots"
                M.special_workspace = "special"

                return M
              '';
            };
          };
        };
      };
    };
}
