# Desktop Host Specific Configuration
# Hardware definitions, rfkill bluetooth workaround for ASUS motherboard WMI,
# Logitech wireless peripheral support, local firewall rules, and state version.
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

      # Desktop-specific USB Bluetooth kernel modules
      boot.kernelModules = [ "btusb" ];

      # Unblock Bluetooth adapter at boot (asus_wmi soft-blocks the adapter on desktop startup)
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

      # Desktop workstation: keep Bluetooth powered on at boot for wireless peripherals
      hardware.bluetooth.powerOnBoot = true;

      # Desktop workstation CPU governor for low gaming latency and high frame pacing
      powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

      hardware.logitech.wireless.enable = true;

      # Spread IRQs across CPU cores (favours gaming throughput on a many-core
      # desktop). Optional: disable if it hurts latency on a given workload.
      services.irqbalance.enable = true;

      environment.systemPackages = with pkgs.unstable; [
        musicpod
        nicotine-plus
        pkgs.stable.calibre
        sigil
      ];

      # Open desktop local discovery & streaming ports
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      # Wi-Fi tuning
      # The only in-range AP for this SSID sits at ~-79 dBm, below iwd's
      # default RoamThreshold5G (-76), so iwd roam-scans every ~60s looking
      # for a better BSSID that doesn't exist. That spikes latency. This is a
      # stationary desktop, so disable roaming scans. (The laptop, which
      # actually roams, keeps the default.)
      networking.wireless.iwd.settings.Scan.DisableRoamingScan = true;

      # Feature toggles (shared and per-host) live in modules/core/options.nix.

      system.stateVersion = "26.05";
    };
}
