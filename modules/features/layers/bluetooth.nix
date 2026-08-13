{ ... }:
{
  nixos.modules.shared =
    { ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.General = {
          DisabledPlugins = "bap";
        };
      };

      services.blueman.enable = true;
    };
}

