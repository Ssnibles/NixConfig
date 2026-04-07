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
    };
    DriverQuirks = {
      # Helps with "IWD is connecting to the wrong AP" and SAE issues on some Realtek chips
      power_save = "disable";
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
