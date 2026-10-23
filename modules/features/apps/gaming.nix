# Gaming on the desktop.
{ self, ... }:
{
  nixos.modules.desktop =
    { pkgs, config, ... }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
      };
      programs.gamemode.enable = true;

      # DualSense controller support.
      boot.kernelModules = [ "hid-playstation" ];
      hardware.steam-hardware.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        dualsensectl
        via
        vintagestory
        self.packages.${pkgs.stdenv.hostPlatform.system}.dualsense-pair
      ];

      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/${config.username}/.steam/root/compatibilitytools.d";
      };
    };
}
