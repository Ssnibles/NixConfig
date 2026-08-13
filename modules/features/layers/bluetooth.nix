{ ... }:
{
  nixos.modules.shared =
    { ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            DisabledPlugins = "bap";
            Experimental = false;
            KernelExperimental = false;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };

      services.blueman.enable = true;

      systemd.services.bluetooth.after = [ "systemd-rfkill.service" ];
    };
}

