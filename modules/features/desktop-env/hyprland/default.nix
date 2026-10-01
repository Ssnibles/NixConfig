{ ... }:
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
            "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
            "org.freedesktop.impl.portal.Screenshot" = "hyprland";
          };
        };

        # hyprland.lua is a live symlink into the checkout (see nixos.liveLinks);
        # the previous jq edit of Hjem's manifest is unnecessary because Hjem
        # only manages .config/hypr/generated.lua.
        nixos.liveLinks."hyprland-config" = {
          source = "${config.nixos.configRepo}/modules/features/desktop-env/hyprland/hyprland.lua";
          target = ".config/hypr/hyprland.lua";
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
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
                M.isDesktop = ${if config.nixos.hostRole == "desktop" then "true" else "false"}
                M.isLaptop = ${if config.nixos.hostRole == "laptop" then "true" else "false"}
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
