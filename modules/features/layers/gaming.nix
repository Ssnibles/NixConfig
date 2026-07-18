{ self, inputs, ... }:
{
  flake.nixosModules.gaming =
    { pkgs, lib, ... }:
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
        heroic
        r2modman
      ];
      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/user/.steam/root/compatibilitytools.d";
      };
    };
}
