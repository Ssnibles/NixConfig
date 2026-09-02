# =============================================================================
# Desktop Host Specific Configuration
# =============================================================================
# Hardware definitions, rfkill bluetooth workaround for ASUS motherboard WMI,
# Logitech wireless peripheral support, local firewall rules, and state version.
# =============================================================================
{ ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        ./_hardware-generated.nix
      ]
      ++ lib.optional (builtins.pathExists ./_installer-options.nix) ./_installer-options.nix;

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

      hardware.logitech.wireless.enable = true;

      environment.systemPackages = with pkgs.unstable; [
        amberol
      ];

      # Open desktop local discovery & streaming ports
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      # ── Desktop Environment Features ───────────────────────────────────────
      features.dwl.enable = true;
      features.hyprland.enable = true;
      features.mangowc.enable = true;
      features.river.enable = false;
      features.niri.enable = false;

      system.stateVersion = "25.11";
    };
}
