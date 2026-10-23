# Desktop host settings.
# Bluetooth workaround for the ASUS motherboard, wireless peripherals, firewall
# ports, and Wi-Fi roaming.
{ ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        ./_hardware-generated.nix
      ]
      ++ lib.optional (builtins.pathExists ./_installer-options.nix) ./_installer-options.nix;

      nixos.hostRole = "desktop";

      # Desktop USB Bluetooth modules.
      boot.kernelModules = [ "btusb" ];

      # asus_wmi blocks the adapter at boot, so unblock it before Bluetooth.
      systemd.services.unblock-bluetooth = {
        description = "Unblock Bluetooth rfkill for ASUS WMI";
        after = [ "sysinit.target" ];
        before = [ "bluetooth.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = 5;
        };
        script = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };

      hardware.bluetooth.powerOnBoot = true;

      # Low latency and steady frame pacing for games.
      powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

      hardware.logitech.wireless.enable = true;

      # Spread interrupts across cores for gaming throughput.
      services.irqbalance.enable = true;

      environment.systemPackages = with pkgs.unstable; [
        musicpod
        nicotine-plus
        pkgs.stable.calibre
        sigil
      ];

      # Local discovery and streaming.
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      # The only access point in range is below iwd's roaming threshold, so
      # roam scans find nothing and only add latency. This desktop does not move.
      networking.wireless.iwd.settings.Scan.DisableRoamingScan = true;

      system.stateVersion = "26.05";
    };
}
