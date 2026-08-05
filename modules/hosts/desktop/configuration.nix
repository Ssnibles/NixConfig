{ ... }:
{
  nixos.modules.desktop =
    { pkgs, lib, config, ... }:
    {
      imports = [
        ./_hardware-generated.nix
      ] ++ lib.optional (builtins.pathExists ./_installer-options.nix) ./_installer-options.nix;

      # Desktop-specific kernel modules
      boot.kernelModules = [ "btusb" ];

      # Unblock Bluetooth at boot — asus_wmi soft-blocks the adapter
      systemd.services.unblock-bluetooth = {
        description = "Unblock Bluetooth rfkill";
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
        keepassxc
        amberol
        chromium
      ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Open ports in the firewall.
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      system.stateVersion = "25.11";
    };
}
