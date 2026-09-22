# =============================================================================
# System Bluetooth Feature
# =============================================================================
# Enables Bluetooth hardware stack, Blueman daemon, and suppresses benign log spam.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { lib, config, ... }:
    {
      options.features.bluetooth.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the system Bluetooth stack and Blueman applet.";
      };

      config = lib.mkIf config.features.bluetooth.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = lib.mkDefault true;
          disabledPlugins = [ "bap" ];
        };

        services.blueman.enable = true;

        # Suppress benign log filter pattern in systemd journal
        systemd.services.bluetooth.serviceConfig.LogFilterPatterns = [ "~Failed to set default system config" ];
      };
    };
}