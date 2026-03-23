{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
  ];

  system.stateVersion = "24.05";
  networking.hostName = "desktop";

  # ── Boot & Kernel ──────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
    systemd-boot.configurationLimit = 10;
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # ── Networking ─────────────────────────────────────────────────────────────
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
    settings = {
      Resolve = {
        FallbackDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        DNSOverTLS = "yes";
        Cache = "yes";
      };
    };
  };

  # ── Hardware Peripherals ───────────────────────────────────────────────────
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
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="nvidia", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="2048"
  '';

  # ── Power Management ───────────────────────────────────────────────────────
  services.power-profiles-daemon.enable = false;
  powerManagement.cpuFreqGovernor = "performance";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';

  # ── Desktop & Audio ────────────────────────────────────────────────────────
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;
  services.flatpak.enable = true;
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

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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

  # ── User Configuration ─────────────────────────────────────────────────────
  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
      "plugdev"
    ];
  };

  # ── Packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    btop
    rsync
    nvme-cli
    smartmontools
    gamemode
  ];

  # ── Locale & Time ──────────────────────────────────────────────────────────
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
  };

  # ── Nix Settings ───────────────────────────────────────────────────────────
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
      keep-generations = 5;
      keep-generations-root = 3;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
  };
}
