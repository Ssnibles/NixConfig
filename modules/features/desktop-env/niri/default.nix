# =============================================================================
# Niri Scrollable-Tiling Compositor Feature
# =============================================================================
# Enables Niri window manager, links config.kdl, and installs helper utilities
# like niri-float-sticky and xwayland-satellite.
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
          tesseract
          xwayland-satellite
          inputs.niri-float-sticky.packages.${pkgs.stdenv.hostPlatform.system}.niri-float-sticky
        ];

        system.activationScripts.niri-config = ''
          mkdir -p /home/${config.username}/.config/niri
          chown -R ${config.username}:users /home/${config.username}/.config/niri
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/niri/config.kdl /home/${config.username}/.config/niri/config.kdl
          chown -h ${config.username}:users /home/${config.username}/.config/niri/config.kdl
        '';
      };
    };
}
