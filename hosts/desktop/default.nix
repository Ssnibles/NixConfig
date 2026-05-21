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

  # ── Lower always-on background services ────────────────────────────────────
  # Bluetooth remains available via D-Bus activation when Blueman is opened.
  hardware.bluetooth.powerOnBoot = lib.mkForce false;
  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];
  services.printing.enable = lib.mkForce false;
  services.avahi.enable = lib.mkForce false;
  services.avahi.nssmdns4 = lib.mkForce false;

  # ── UDEV rules ───────────────────────────────────────────────────────────
  services.udev.extraRules = ''
    # Keep USB HID devices powered on
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
    # Keep NVIDIA GPU powered on
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="nvidia", ATTR{power/control}="on"
    # Higher NVMe read-ahead for desktop performance
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="2048"
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
