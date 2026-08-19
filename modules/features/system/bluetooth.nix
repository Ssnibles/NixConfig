# =============================================================================
# System Bluetooth Feature
# =============================================================================
# Enables Bluetooth hardware stack, Blueman daemon, and suppresses benign log spam.
# =============================================================================
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

      # Suppress benign log filter pattern in systemd journal
      systemd.services.bluetooth.serviceConfig.LogFilterPatterns = [ "~Failed to set default system config" ];
    };
}
