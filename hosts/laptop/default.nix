# =============================================================================
# Laptop Host Configuration
# =============================================================================
# AMD CPU laptop with integrated graphics.
# =============================================================================
{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  # WiFi regulatory domain and Realtek driver fixes
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
    options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
    options rtw89_core disable_ps_mode=y
  '';

  # ── Networking ───────────────────────────────────────────────────────────
  networking.wireless.iwd.settings = {
    General = {
      EnableNetworkConfiguration = false;
      # Keep iwd and cfg80211 aligned on regulatory rules so 5GHz channels
      # permitted in the local domain are available for scan/connect.
      Country = "NZ";
    };
    DriverQuirks = {
      # Disable power save for rtw89 variants (value is a driver glob list).
      PowerSaveDisable = "rtw89*";
    };
  };

  # ── Power management – TLP ────────────────────────────────────────────────
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 85;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";
      USB_AUTOSUSPEND = 1;
      AHCI_RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      LAPTOP_MODE = 5;
    };
  };

  # Keyd: Keyboard remapping daemon (system-level, works in all environments)
  # Swaps CapsLock ↔ Escape (Vim-friendly, available even in TTY)
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ]; # Apply to all keyboards
      settings.main = {
        capslock = "esc";
        esc = "capslock";
      };
    };
  };

  # ── Lid switch behaviour ─────────────────────────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IgnoreInhibited = "yes";
  };

  # ── UDEV rules ───────────────────────────────────────────────────────────
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="1024"
  '';
}
