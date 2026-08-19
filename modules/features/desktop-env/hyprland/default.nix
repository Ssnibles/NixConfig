# =============================================================================
# Hyprland Wayland Compositor Feature
# =============================================================================
# Hyprland window manager with Quickshell status bar, Hyprpaper wallpaper daemon,
# and Hyprshot screenshot integration.
# =============================================================================
{ self, ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.hyprland.enable = true;

        environment.systemPackages = with pkgs; [
          hyprpaper
          hyprshot
          seahorse
        ];

        programs.seahorse.enable = true;

        xdg.portal.extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/hypr/hyprland.lua" = {
              source = ./hyprland.lua;
            };
            ".config/hypr/generated.lua" = {
              source = ./generated.lua;
            };
          };
        };
      };
    };
}
