# Gaming stack. Hosts with a GPU and a controller enable features.gaming.
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
      cfg = config.features.gaming;
      home = config.users.users.${config.username}.home;
    in
    {
      options.features.gaming.enable = lib.mkEnableOption "Steam, gamemode and controller support";

      config = lib.mkIf cfg.enable {
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
          STEAM_EXTRA_COMPAT_TOOLS_PATH = "${home}/.steam/root/compatibilitytools.d";
        };
      };
    };
}
