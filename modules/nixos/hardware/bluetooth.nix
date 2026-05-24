{ lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = lib.mkDefault false;
    settings.General = {
      FastConnectable = true;
      Experimental = true;
    };
  };
  systemd.services.bluetooth.wantedBy = lib.mkDefault [ ];
}
