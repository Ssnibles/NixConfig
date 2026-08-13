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
    };
}

