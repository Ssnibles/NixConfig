# =============================================================================
# Common NixOS Configuration
# =============================================================================
# Shared system settings applied to every host.
# Host-specific overrides live in hosts/<name>/configuration.nix.
# Uses lib.mkDefault throughout so individual hosts can override freely.
# =============================================================================
{
  config,
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  # ── System State Version ─────────────────────────────────────────────────
  system.stateVersion = "24.05";

  # ── Hostname ─────────────────────────────────────────────────────────────
  networking.hostName = hostProfile.hostName;

  # ── Boot & Kernel ────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable = true;
      # Retain only the last 10 generations to save EFI space
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Latest kernel by default; NVIDIA hosts override this to stable in nvidia.nix
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Proprietary firmware (WiFi, Bluetooth, etc.)
  hardware.enableRedistributableFirmware = true;

  # ── Networking ───────────────────────────────────────────────────────────
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd"; # Better WiFi performance than wpa_supplicant
        powersave = false; # Prevents random disconnects
        macAddress = "random"; # Privacy on new networks
      };
      dns = "systemd-resolved";
    };

    firewall = {
      enable = true;
      # LocalSend (cross-device file transfer) port
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };

    enableIPv6 = true;
  };

  # DNS-over-TLS via systemd-resolved
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade"; # Avoid outages if DNSSEC fails
    dnsovertls = "opportunistic"; # Encrypt where possible, fall back gracefully
    domains = [ "~." ];
    settings.Resolve = {
      DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111";
      FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
      Cache = "yes";
    };
  };

  # ── Hardware ─────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      FastConnectable = true;
      Experimental = true;
    };
  };

  # ── Power Management ─────────────────────────────────────────────────────
  # Desktop uses powerManagement.cpuFreqGovernor = "performance" (set in host config).
  # Laptop overrides with TLP.  Disable the daemon here so neither host conflicts.
  services.power-profiles-daemon.enable = false;

  # Compressed RAM swap — better than hitting disk for most workloads
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # ── Desktop Environment ──────────────────────────────────────────────────
  # Login screen
  services.displayManager.ly.enable = true;

  # Wayland compositor (system-level enablement; user config is in Home Manager)
  programs.hyprland.enable = true;

  # XDG desktop portal — required for screen sharing on Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.hyprland ];
  };

  # ── Audio ────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # Low-latency tuning: 48 kHz / 1024-sample quantum (~21 ms)
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 1024;
      };
    };
  };

  # ── System Services ──────────────────────────────────────────────────────
  # Network printer discovery
  services.printing.enable = true;

  # mDNS for local network discovery (printers, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Bluetooth manager GUI
  services.blueman.enable = true;

  # Remap CapsLock ↔ Escape at the kernel level
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

  # Flatpak sandbox for third-party apps
  services.flatpak.enable = true;

  # Fish shell must be enabled system-wide so it appears in /etc/shells
  programs.fish.enable = true;

  # Cap journal size to prevent disk fill
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';

  # ── Users ────────────────────────────────────────────────────────────────
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

  # ── Base System Packages ─────────────────────────────────────────────────
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

  # ── Locale & Time ────────────────────────────────────────────────────────
  time.timeZone = "Pacific/Auckland";
  i18n = {
    defaultLocale = "en_NZ.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_NZ.UTF-8";
      LC_MEASUREMENT = "en_NZ.UTF-8";
    };
  };

  # ── Nix Settings ─────────────────────────────────────────────────────────
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
