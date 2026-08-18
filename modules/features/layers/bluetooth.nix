{ ... }:
{
  nixos.modules.shared =
    { ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        disabledPlugins = [ "bap" ];
      };

      services.blueman.enable = true;

      systemd.services.bluetooth.serviceConfig.LogFilterPatterns = [ "~Failed to set default system config" ];
    };
}

