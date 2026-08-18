{ ... }:
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
      environment.systemPackages = with pkgs; [
        mangohud
        protonup-ng
      ];
      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/${config.username}/.steam/root/compatibilitytools.d";
      };
    };
}
