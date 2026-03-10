{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    wifi.powersave = false;
    dns = "systemd-resolved";
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
      };
      Network = {
        EnableIPv6 = true;
      };
    };
  };

  services.resolved.enable = true;

  services.logind.lidSwitch = "suspend";
  services.logind.lidSwitchExternalPower = "suspend";

  # Bluetooth Configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # This prevents Bluetooth from forcing itself on at boot
    settings = {
      General = {
        Experimental = true;
        # This helps bluez remember the state from the previous session
        AutoEnable = false;
      };
    };
  };

  # Display & Desktop
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.hyprland.enable = true;

  # Services
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.polkit.enable = true;
  services.gvfs.enable = true;
  services.flatpak.enable = true;
  services.blueman.enable = true;

  # User Configuration
  users.users.josh = {
    isNormalUser = true;
    description = "Josh";
    extraGroups = [ "networkmanager" "wheel" "video" "adbusers" ];
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    git
    vim
    networkmanagerapplet
  ];

  # Locale & Time
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  system.stateVersion = "25.05";
}
