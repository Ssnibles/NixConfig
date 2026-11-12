# Niri compositor.
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
      cfg = config.features.niri;
    in
    {
      options.features.niri.enable = lib.mkEnableOption "the Niri Wayland compositor";

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
