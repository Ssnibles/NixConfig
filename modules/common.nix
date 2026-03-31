# =============================================================================
# Common Host Configuration
# =============================================================================
# Shared settings between desktop and laptop to reduce duplication.
# Contains all configuration that is identical across hosts.
# Host-specific overrides remain in individual configuration.nix files.
#
# This module is imported by both hosts/desktop and hosts/laptop.
# Uses lib.mkDefault so host-specific configs can override when needed.
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
  # Tracks NixOS configuration schema version.
  # Only change when running nixos-rebuild with --upgrade flag.
  system.stateVersion = "24.05";

  # ── Hostname ─────────────────────────────────────────────────────────────
  # Set from hostProfile for network identification.
  networking.hostName = hostProfile.hostName;

  # ── Boot & Kernel ────────────────────────────────────────────────────────
  boot.loader = {
    # systemd-boot is fast and simple for UEFI systems
    systemd-boot.enable = true;
    # Allow NixOS to manage EFI boot entries
    efi.canTouchEfiVariables = true;
    # Short timeout for faster boot
    timeout = 3;
    # Keep only last 10 generations to save space
    systemd-boot.configurationLimit = 10;
  };

  # Default to latest kernel for hardware support.
  # Uses mkDefault so hosts can override (e.g., NVIDIA needs stable kernel).
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Include proprietary firmware for WiFi, Bluetooth, etc.
  hardware.enableRedistributableFirmware = true;

  # ── Networking ───────────────────────────────────────────────────────────
  networking = {
    # NetworkManager for WiFi and connection management
    networkmanager = {
      enable = true;
      # Use iwd backend for better WiFi performance
      wifi.backend = "iwd";
      # Disable WiFi power saving (causes disconnects)
      wifi.powersave = false;
      # Use systemd-resolved for DNS
      dns = "systemd-resolved";
      # Randomize MAC address for privacy on new networks
      wifi.macAddress = "random";
    };

    # Firewall configuration
    firewall = {
      enable = true;
      # Ollama API port
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };

    enableIPv6 = true;
  };

  # DNS over TLS for privacy
  services.resolved = {
    enable = true;
    # Allow downgrade if DoT fails (prevents DNS outages)
    dnssec = "allow-downgrade";
    # Try encrypted DNS, fall back to plaintext if needed
    dnsovertls = "opportunistic";
    domains = [ "~." ];
    settings = {
      Resolve = {
        # Cloudflare DNS with DoT
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111";
        # Google DNS as fallback
        FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
        # Enable DNS caching
        Cache = "yes";
      };
    };
  };

  # ── Hardware Peripherals ─────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      FastConnectable = true;
      Experimental = true;
    };
  };

  # Bluetooth manager GUI
  services.blueman.enable = true;

  # ── Power Management ─────────────────────────────────────────────────────
  # Disable power-profiles-daemon (TLP handles this on laptop).
  # Laptop config will override with TLP if needed.
  services.power-profiles-daemon.enable = false;

  # Compressed RAM swap for better performance than disk swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Limit journal size to prevent disk fill
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';

  # ── Desktop & Audio ──────────────────────────────────────────────────────
  # Display manager (login screen)
  services.displayManager.ly.enable = true;

  # Wayland compositor
  programs.hyprland.enable = true;

  # Flatpak support for additional applications
  services.flatpak.enable = true;

  # Fish shell system-wide
  programs.fish.enable = true;

  # Audio server with low-latency configuration
  # This enables microphone and screen sharing backend (PipeWire)
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

  # Printing support
  services.printing.enable = true;

  # mDNS for network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Keyboard remapping daemon (CapsLock ↔ Escape swap)
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

  # ── User Configuration ───────────────────────────────────────────────────
  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager" # WiFi management
      "wheel" # Sudo access
      "video" # GPU access
      "input" # Input device access
      "plugdev" # USB device access
    ];
  };

  # ── Base Packages ────────────────────────────────────────────────────────
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
  i18n.defaultLocale = "en_NZ.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
  };

  # ── Nix Settings ─────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Optimize store by hard-linking identical files
      auto-optimise-store = true;
      # Binary caches for faster builds
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # ── XDG Desktop Portal (Screen Sharing Support) ──────────────────────────
  # Required for screen sharing in Firefox, Chrome, Discord, Zoom, etc.
  # on Wayland/Hyprland.
  xdg.portal = {
    enable = true;
    # Use the Hyprland-specific portal for screen sharing
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    # Ensure hyprland is available for portal config
    configPackages = [ pkgs.hyprland ];
  };
}
