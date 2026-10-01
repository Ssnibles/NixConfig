# =============================================================================
# Niri Scrollable-Tiling Compositor Feature
# =============================================================================
# Enables Niri window manager, links config.kdl, and installs helper utilities
# like xwayland-satellite.
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
      cfg = config.features.niri;
    in
    {
      options.features.niri.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Niri Wayland compositor feature.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.niri.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite
        ];

        nixos.liveLinks."niri-config" = {
          source = "${config.nixos.configRepo}/modules/features/desktop-env/niri/config.kdl";
          target = ".config/niri/config.kdl";
        };
      };
    };
}
