{
  config,
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/nvidia.nix
  ];

  # ── Nix ───────────────────────────────────────────────────────────────────

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05"; # do not change

  # ── Boot ──────────────────────────────────────────────────────────────────

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # mkDefault lets nvidia.nix override this with the stable LTS kernel.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true;

  # Disable USB autosuspend — prevents input-device drop-outs.
  boot.kernelParams = lib.mkIf (!hostProfile.isVM) [ "usbcore.autosuspend=-1" ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
    options iwlwifi bt_coex_active=1
  '';

  # ── Networking ────────────────────────────────────────────────────────────

  networking = {
    hostName = hostProfile.hostName;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      wifi.powersave = hostProfile.isLaptop;
      dns = "systemd-resolved";
    };
    firewall = {
      enable = true;
      # Keep these ports open for localsend
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────────

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── Power ─────────────────────────────────────────────────────────────────

  # power-profiles-daemon conflicts with TLP.
  services.power-profiles-daemon.enable = false;

  services.tlp = lib.mkIf (hostProfile.isLaptop && !hostProfile.isVM) {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      STOP_CHARGE_THRESH_BAT0 = 85;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      USB_AUTOSUSPEND = 0;
    };
  };

  powerManagement = {
    cpuFreqGovernor = lib.mkIf (hostProfile.isDesktop && !hostProfile.isVM) "performance";
    powertop.enable = hostProfile.isLaptop && !hostProfile.isVM;
  };

  zramSwap.enable = true;

  # Keep HID devices (keyboards, mice) awake — class 0x03 = HID.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
  '';

  # ── Display / desktop ─────────────────────────────────────────────────────

  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;
  services.flatpak.enable = true;

  services.logind.settings = lib.mkIf hostProfile.isLaptop {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # ── Audio ─────────────────────────────────────────────────────────────────

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ── Key remapping ─────────────────────────────────────────────────────────

  # Swap CapsLock ↔ Escape system-wide (works in TTY, Wayland, X).
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "esc";
        esc = "capslock";
      };
    };
  };

  # ── Shell ─────────────────────────────────────────────────────────────────

  programs.fish.enable = true;

  # ── User ──────────────────────────────────────────────────────────────────

  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
      "adbusers"
    ];
  };

  # ── System packages — keep minimal, prefer home.nix ──────────────────────

  environment.systemPackages = with pkgs; [
    git
    vim
    iw
  ];

  # ── Locale / timezone ─────────────────────────────────────────────────────

  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";
}
