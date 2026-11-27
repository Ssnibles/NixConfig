# Desktop host settings.
# Bluetooth workaround for the ASUS motherboard, wireless peripherals, firewall
# ports, and Wi-Fi roaming. Hardware comes from _hardware-generated.nix.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixos.hostRole = "desktop";

  features = {
    hyprland.enable = true;
    minecraft.enable = true;
    gaming.enable = true;
    nvidia.enable = true;

    # The library lives on the second NVMe. The converted copies follow it,
    # so neither tree grows the root filesystem.
    beets = {
      directory = "~/data/Media/Music";
      convertDest = "~/data/Media/Music-converted";
    };
  };

  # The desktop is a fixed, single-user workstation, so CPU mitigations
  # and the watchdog are traded for performance here only.
  boot.kernelParams = [
    "mitigations=off"
    "nowatchdog"
  ];

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

  environment.systemPackages = with pkgs; [
    musicpod
    pkgs.stable.calibre
    sigil
  ];

  networking = {
    # Local discovery and streaming.
    firewall = {
      allowedTCPPorts = [
        5353
        9090
      ];
      allowedUDPPorts = [ 5353 ];
    };

    # The only access point in range is below iwd's roaming threshold, so
    # roam scans find nothing and only add latency. This desktop does not move.
    wireless.iwd.settings.Scan.DisableRoamingScan = true;
  };

  # Second NVMe: a plain ext4 data volume. Label, not UUID, so reformatting
  # the partition does not need a config change. The same disk carries /boot,
  # so it can never be absent at boot and needs no nofail.
  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Plain `L`, not `L+`: if a real directory ever lands at that path, tmpfiles
  # leaves it alone instead of deleting it to make room for the link.
  systemd.tmpfiles.rules = [
    "L /home/${config.username}/data - ${config.username} users - /data"
  ];

  system.stateVersion = "26.05";
}
