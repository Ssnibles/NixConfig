# Bluetooth support.
{ ... }:
{
  nixos.modules.shared =
    { lib, config, ... }:
    {
      options.features.bluetooth.enable = lib.mkEnableOption "the system Bluetooth stack and Blueman applet";

      config = lib.mkIf config.features.bluetooth.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = lib.mkDefault true;
          disabledPlugins = [ "bap" ];
        };

        services.blueman.enable = true;

        # This message is harmless and only adds noise to the journal.
        systemd.services.bluetooth.serviceConfig.LogFilterPatterns = map (
          p: "~${p}"
        ) config.nixos.journalNoisePatterns;
      };
    };
}
