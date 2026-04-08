# =============================================================================
# Common NixOS Configuration
# =============================================================================
# Shared system settings applied to all hosts in this flake.
# Host-specific overrides live in hosts/<name>/configuration.nix.
#
# Design Principles:
#   • Uses lib.mkDefault throughout to allow host-level overrides
#   • Performance-tuned for modern hardware (NVMe, fast RAM, SSD)
#   • Security-conscious (firewall, DNS-over-TLS, minimal attack surface)
#   • Wayland-first desktop environment (Hyprland compositor)
#   • Optimized for developer workflow (Fish shell, Neovim, LSP tools)
#
# Module Structure:
#   1. System State Version
#   2. Boot & Kernel Configuration
#   3. Networking (NetworkManager, DNS-over-TLS, Firewall)
#   4. Hardware (Bluetooth, Firmware)
#   5. Power Management (zram, TRIM, power profiles)
#   6. Desktop Environment (Hyprland, Login Manager, XDG Portal)
#   7. Audio (PipeWire with low-latency tuning)
#   8. System Services (Printing, mDNS, Nix helpers, Flatpak)
#   9. User Configuration
#  10. Base System Packages
#  11. Locale & Time
#  12. Nix Settings (Flakes, Binary Cache, GC)
# =============================================================================
{
  config,
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM STATE VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  # DO NOT CHANGE: This value determines the NixOS release with which your
  # system is to be compatible, in order to avoid breaking some software.
  # Update only when following the official NixOS release upgrade guide.
  system.stateVersion = "24.05";

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOT & KERNEL
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader = {
    systemd-boot = {
      enable = true;
      # EFI partition space management: keep only recent generations
      # Prevents boot failures when /boot fills up (ESP typically 512MB-1GB)
      configurationLimit = 10;
      # High-resolution boot menu for modern displays
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
    # Fast boot: 3-second timeout allows manual intervention if needed
    timeout = 3;
  };

  # Latest kernel for modern hardware support and performance improvements
  # NVIDIA hosts override to stable kernel in nvidia.nix for driver compatibility
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Enable proprietary firmware (WiFi chipsets, Bluetooth adapters, etc.)
  # Required for most modern laptops and wireless hardware
  hardware.enableRedistributableFirmware = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # NETWORKING
  # ═══════════════════════════════════════════════════════════════════════════
  # ═══════════════════════════════════════════════════════════════════════════
  # NETWORKING
  # ═══════════════════════════════════════════════════════════════════════════
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        # iwd backend: faster, more reliable than wpa_supplicant
        # Supports modern WiFi 6E features, better roaming
        backend = "iwd";
        # Disable power saving to prevent random disconnects
        # Laptop-specific power management is handled by TLP
        powersave = lib.mkDefault false;
        # Stable MAC addresses per network for DHCP lease consistency
        # Improves privacy vs. random MAC while maintaining functionality
        macAddress = "stable";
      };
      # systemd-resolved provides split-DNS and DNS-over-TLS
      dns = "systemd-resolved";
    };

    firewall = {
      enable = true;
      # LocalSend: cross-platform file transfer app (LAN discovery)
      # Port 53317 for both TCP (transfers) and UDP (discovery)
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };

    # IPv6 enabled by default (most ISPs and LANs support it now)
    enableIPv6 = true;
  };

  # DNS-over-TLS configuration via systemd-resolved
  # Encrypts DNS queries to prevent eavesdropping and manipulation
  services.resolved = {
    enable = true;
    # Allow downgrade if DNSSEC validation fails (prevents outages)
    dnssec = "allow-downgrade";
    # Opportunistic TLS: encrypt when supported, fall back if not
    # More reliable than "true" (strict) for diverse network environments
    dnsovertls = "opportunistic";
    # Route all DNS queries through systemd-resolved
    domains = [ "~." ];
    extraConfig = ''
      [Resolve]
      # Primary: Cloudflare DNS (1.1.1.1) with DNS-over-TLS
      DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111
      # Fallback: Google DNS (8.8.8.8) for redundancy
      FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google
      # Cache DNS responses to reduce latency and network traffic
      Cache=yes
    '';
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # HARDWARE
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Auto-enable Bluetooth on system start
    settings.General = {
      # Faster connection establishment for Bluetooth devices
      FastConnectable = true;
      # Enable experimental features (better codec support, LE Audio)
      Experimental = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # POWER MANAGEMENT
  # ═══════════════════════════════════════════════════════════════════════════
  # Disable power-profiles-daemon to avoid conflicts:
  # • Desktop uses: powerManagement.cpuFreqGovernor = "performance"
  # • Laptop uses: TLP (more granular control)
  services.power-profiles-daemon.enable = false;

  # SSD TRIM: automatic weekly SSD garbage collection
  # Improves performance and longevity of SSDs
  services.fstrim.enable = true;

  # zram: compressed swap in RAM (faster than disk swap)
  # Typical compression ratio: 3:1 (6GB RAM = 18GB swap)
  # Priority 100: higher than disk swap (if configured)
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Fast compression, good ratio
    priority = 100;     # Prefer zram over disk swap
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # DESKTOP ENVIRONMENT
  # ═══════════════════════════════════════════════════════════════════════════
  # Ly: Lightweight TUI display manager (no dependencies on heavy DEs)
  # Fast boot, minimal resource usage, clean aesthetic
  services.displayManager.ly.enable = true;

  # Hyprland: Modern Wayland compositor (system-level enablement)
  # User-specific configuration lives in modules/home/desktop/hyprland.nix
  programs.hyprland.enable = true;

  # XDG Desktop Portal: Required for screen sharing on Wayland
  # Enables: PipeWire screen capture, file pickers, system integrations
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.hyprland ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO
  # ═══════════════════════════════════════════════════════════════════════════
  # RealtimeKit: Allows PipeWire to request real-time scheduling
  # Reduces audio latency and prevents dropouts under system load
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;   # ALSA compatibility layer
    pulse.enable = true;  # PulseAudio compatibility layer
    wireplumber.enable = true; # Session manager (replaces pipewire-media-session)

    # Low-latency configuration for professional audio work and gaming
    # 48kHz sample rate, 1024 samples/quantum = ~21ms latency
    # Balance between latency and CPU usage (512 = lower latency, higher CPU)
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;    # CD-quality sample rate
        default.clock.quantum = 1024;  # Buffer size (~21ms at 48kHz)
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM SERVICES
  # ═══════════════════════════════════════════════════════════════════════════
  # CUPS: Network printer support
  services.printing.enable = true;

  # Avahi: mDNS/DNS-SD for local network service discovery
  # Enables automatic printer and network device detection
  services.avahi = {
    enable = true;
    nssmdns4 = true;     # NSS module for .local domain resolution
    openFirewall = true; # Allow mDNS traffic (UDP 5353)
  };

  # Nix Helper (nh): Enhanced nixos-rebuild with better UX
  # Features: progress bars, better error messages, automatic GC
  programs.nh = {
    enable = true;
    clean.enable = true;
    # Garbage collection: keep builds from last 4 days, minimum 3 generations
    # Prevents accidental deletion of recent working configs
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/josh/NixConfig";
  };

  # Nix-index: Fast "command not found" handler
  # Suggests packages to install when running unknown commands
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false; # Replaced by nix-index

  # Nix-ld: Run unpatched binaries (e.g., downloaded precompiled apps)
  # Provides FHS-compatible loader for non-Nix binaries
  programs.nix-ld.enable = true;

  # Blueman: Graphical Bluetooth manager
  # Provides system tray icon and GUI for pairing devices
  services.blueman.enable = true;

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

  # Flatpak: Sandboxed application distribution
  # Useful for proprietary apps not available in nixpkgs (e.g., Discord, Slack)
  services.flatpak.enable = true;

  # Fish Shell: System-wide enablement (required for /etc/shells and user login)
  # User-specific Fish configuration is in modules/home/shell/fish.nix
  programs.fish.enable = true;

  # Systemd Journal: Cap log size to prevent disk exhaustion
  # 500MB limit, 1-week retention for troubleshooting
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1week
  '';

  # ═══════════════════════════════════════════════════════════════════════════
  # USERS
  # ═══════════════════════════════════════════════════════════════════════════
  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    shell = pkgs.fish; # User shell (Fish configuration in Home Manager)
    # Group memberships for system access:
    # • networkmanager: WiFi/network control without sudo
    # • wheel: sudo privileges
    # • video: GPU access, screen brightness control
    # • input: Wayland input device access
    # • plugdev: USB device access
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
      "plugdev"
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # BASE SYSTEM PACKAGES
  # ═══════════════════════════════════════════════════════════════════════════
  # Essential tools available system-wide (before Home Manager loads)
  # User packages are defined in modules/home/packages.nix
  environment.systemPackages = with pkgs.unstable; [
    # Version control
    git

    # System libraries (required by some applications)
    glib           # GTK+ framework core library
    glib-networking # Network extensions for GLib applications
    dconf          # GNOME configuration database (used by many apps)

    # Text editors (fallback if Neovim fails to load)
    vim

    # System monitoring
    htop           # Interactive process viewer
    btop           # Modern resource monitor with graphs

    # System utilities
    rsync          # File synchronization
    nvme-cli       # NVMe drive management and monitoring
    smartmontools  # HDD/SSD health monitoring (SMART)
    iwd            # WiFi daemon (NetworkManager backend)
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # LOCALE & TIME
  # ═══════════════════════════════════════════════════════════════════════════
  time.timeZone = "Pacific/Auckland"; # New Zealand timezone

  i18n = {
    defaultLocale = "en_NZ.UTF-8"; # English (New Zealand) locale
    extraLocaleSettings = {
      LC_TIME = "en_NZ.UTF-8";        # Time/date formats (DD/MM/YYYY)
      LC_MEASUREMENT = "en_NZ.UTF-8"; # Metric system
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  # Allow proprietary packages (NVIDIA drivers, VSCode, etc.)
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      # Enable modern Nix features (required for flakes)
      experimental-features = [
        "nix-command" # New CLI interface (nix build, nix run, etc.)
        "flakes"      # Reproducible package management with lock files
      ];

      # Store optimization: Hard-link identical files to save disk space
      # Runs automatically during garbage collection
      auto-optimise-store = true;

      # Suppress warnings about uncommitted changes in flake repository
      # Safe since we control the flake source
      warn-dirty = false;

      # Remote builders can use binary caches (improves distributed builds)
      builders-use-substitutes = true;

      # Binary caches: Download pre-built packages instead of building locally
      substituters = [
        "https://cache.nixos.org"         # Official NixOS cache
        "https://nix-community.cachix.org" # Community packages (Hyprland, etc.)
      ];

      # Public keys for binary cache verification (security)
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Garbage collection: Disabled (managed by programs.nh.clean instead)
    # nh provides better UX with keep-since/keep-min policies
    gc = {
      automatic = false;
    };
  };
}
