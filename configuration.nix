{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # ===========================================================================
  # NIX SETTINGS
  # ===========================================================================

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Never change this after the initial install.
  system.stateVersion = "25.05";

  # ===========================================================================
  # BOOT & HARDWARE
  # ===========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Latest kernel for better hardware support.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Firmware blobs required by most hardware (Wi-Fi, Bluetooth, GPU, etc.)
  hardware.enableRedistributableFirmware = true;

  # Disable USB autosuspend globally — fixes input devices randomly dropping
  # on the X570 chipset's PCIe-connected USB controller.
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # NZ Wi-Fi regulatory domain — survives sleep/resume (unlike localCommands).
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
    options iwlwifi bt_coex_active=1
  '';

  # ===========================================================================
  # NETWORKING & WI-FI
  # ===========================================================================

  networking.hostName = "nixos";

  networking.networkmanager = {
    enable = true;

    # iwd: modern Wi-Fi backend, faster and more reliable than wpa_supplicant.
    # Do NOT also set networking.wireless.iwd.enable — NM manages the iwd
    # daemon internally; two instances fight over the interface.
    wifi.backend = "iwd";

    # Disable Wi-Fi power saving — negligible savings, causes latency spikes.
    wifi.powersave = false;

    dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    # Fallback DNS if DHCP-assigned servers are unreliable.
    settings.Resolve.FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
  };

  # ===========================================================================
  # BLUETOOTH
  # ===========================================================================

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # ===========================================================================
  # POWER MANAGEMENT
  # ===========================================================================

  # power-profiles-daemon conflicts with TLP.
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Stop charging at 85% to extend battery lifespan.
      STOP_CHARGE_THRESH_BAT0 = 85;

      # Belt-and-suspenders: TLP can override NM's powersave = false.
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";

      # Don't let TLP touch Bluetooth power — let the BT stack manage itself.
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "";

      # Disable USB autosuspend via TLP as well — belt-and-suspenders alongside
      # the usbcore.autosuspend=-1 kernel param above.
      USB_AUTOSUSPEND = 0;
    };
  };

  powerManagement.powertop.enable = true;

  # Prevent udev from marking USB HID devices (keyboards, mice) as
  # candidates for autosuspend regardless of other power management settings.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
  '';

  # ===========================================================================
  # DISPLAY & DESKTOP
  # ===========================================================================

  # ly: minimal TUI display manager. Picks up Hyprland from wayland-sessions.
  services.displayManager.ly.enable = true;

  programs.hyprland.enable = true;

  # Lid behaviour: suspend on close, ignore when on AC.
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # ===========================================================================
  # AUDIO (PipeWire)
  # ===========================================================================

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ===========================================================================
  # KEYD
  # ===========================================================================

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "esc";
          esc = "capslock";
        };
      };
    };
  };

  # ===========================================================================
  # USER
  # ===========================================================================

  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input" # required for Wayland/Hyprland input device access
      "adbusers"
    ];
  };

  # ===========================================================================
  # SYSTEM PACKAGES
  # Prefer home.nix for per-user packages. Only put things here that must exist
  # before home-manager runs, or need to be available system-wide.
  # ===========================================================================

  environment.systemPackages = with pkgs; [
    git # needed early for flake operations
    vim # emergency editor if neovim breaks
    networkmanagerapplet
    iw # Wi-Fi debugging: `iw dev`, `iw reg get`, etc.
  ];

  # ===========================================================================
  # LOCALE & TIMEZONE
  # ===========================================================================

  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";
}

