# =============================================================================
# Gaming Applications Feature (Desktop Host)
# =============================================================================
# Steam with Millennium skin overlay support, Gamescope session integration,
# GameMode performance daemon, and PlayStation DualSense controller drivers.
# =============================================================================
{ self, ... }:
{
  nixos.modules.desktop =
    { pkgs, config, ... }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;
        gamescopeSession.enable = true;
      };
      programs.gamemode.enable = true;

      # DualSense controller kernel support & pairing utilities
      boot.kernelModules = [ "hid-playstation" ];
      hardware.steam-hardware.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        protonup-ng
        dualsensectl
        via
        self.packages.${pkgs.stdenv.hostPlatform.system}.dualsense-pair
      ];

      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/${config.username}/.steam/root/compatibilitytools.d";
      };
    };
}
