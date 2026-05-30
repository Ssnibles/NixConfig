# =============================================================================
# Desktop Host Configuration
# =============================================================================
# AMD CPU + NVIDIA GPU desktop.
# =============================================================================
{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware.nix
  ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  # Prevent USB autosuspend – fixes keyboard / mouse wake-up issues
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # ── Power management ─────────────────────────────────────────────────────
  # Desktop stays on performance governor; no TLP needed.
  powerManagement.cpuFreqGovernor = "performance";

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  # Ensure the kernel module loads early
  boot.kernelModules = [ "btusb" ];
  # Start Bluetooth at boot and power on the controller.
  hardware.bluetooth.powerOnBoot = lib.mkForce true;
  systemd.services.bluetooth.wantedBy = lib.mkForce [ "multi-user.target" ];
  # Unblock Bluetooth at boot – asus_wmi soft-blocks the adapter
  systemd.services.unblock-bluetooth = {
    description = "Unblock Bluetooth rfkill";
    after = [ "sysinit.target" ];
    before = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
  };

  # ── Lower always-on background services ────────────────────────────────────
  services.printing.enable = lib.mkForce false;
  services.avahi.enable = lib.mkForce false;
  services.avahi.nssmdns4 = lib.mkForce false;

  # Enable Solaar service natively (Handles all UDEV rules and permissions automatically)
  hardware.logitech.wireless.enable = true;

  # ── UDEV rules ───────────────────────────────────────────────────────────
  services.udev.extraRules = ''
    # Keep USB HID devices powered on
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"

    # Keep NVIDIA GPU powered on
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="nvidia", ATTR{power/control}="on"

    # Higher NVMe read-ahead for desktop performance
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/read_ahead_kb}="2048"
  '';

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    gamemode
  ];
}
