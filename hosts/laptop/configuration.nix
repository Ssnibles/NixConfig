# =============================================================================
# Laptop Host Configuration
# =============================================================================
# Production laptop with TLP power management.
# When useDisko = true: Disko handles partitioning (hardware-configuration.nix skipped)
# When useDisko = false: hardware-configuration.nix provides filesystem definitions
# =============================================================================
{
  config,
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  # Only import hardware-configuration.nix for test hosts (useDisko = false)
  imports = lib.optionals (!hostProfile.useDisko) [
    ./hardware-configuration.nix
  ];

  # Kernel modules from hardware-configuration.nix (safe with Disko)
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  system.stateVersion = "24.05";
  networking.hostName = "laptop";

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
    systemd-boot.configurationLimit = 10;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
    options iwlwifi bt_coex_active=1 11n_disable=0
  '';

  # Networking
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      wifi.powersave = false;
      dns = "systemd-resolved";
      wifi.macAddress = "random";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
    enableIPv6 = true;
  };
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    dnsovertls = "opportunistic";
    domains = [ "~." ];
    settings = {
      Resolve = {
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111";
        FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
        Cache = "yes";
      };
    };
  };

  # Hardware
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      FastConnectable = true;
      Experimental = true;
    };
  };
  services.blueman.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="1024"
  '';

  # Power management (TLP)
  services.power-profiles-daemon.enable = false;
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
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
      IgnoreInhibited = "yes";
    };
  };

  # Services
  services.displayManager.ly.enable = true;
  services.flatpak.enable = true;
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
  programs.hyprland.enable = true;
  programs.fish.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 1024;
      };
    };
  };
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

  # User
  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    btop
    rsync
    nvme-cli
    smartmontools
    iwd
  ];

  # Locale
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
  };

  # Nix
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
