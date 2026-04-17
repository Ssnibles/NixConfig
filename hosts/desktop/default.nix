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
  # Ensure the Wi-Fi regulatory domain includes local 5GHz channels.
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
  '';

  # ── Power management ─────────────────────────────────────────────────────
  # Desktop stays on performance governor; no TLP needed.
  powerManagement.cpuFreqGovernor = "performance";

  # ── WiFi stability ────────────────────────────────────────────────────────
  # Keep iwd backend (user preference), but relax DNS strictness to reduce
  # perceived WiFi flakiness on networks with weak DNSSEC/DoT support.
  networking.networkmanager.wifi.powersave = false;
  networking.wireless.iwd.settings.General.Country = "NZ";

  services.resolved = {
    dnssec = lib.mkForce "allow-downgrade";
    dnsovertls = lib.mkForce "opportunistic";
  };

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

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    gamemode
  ];
}
