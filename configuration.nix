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

  # Networking - Fixed: removed standalone iwd (conflicts with NetworkManager)
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    dns = "systemd-resolved";
  };
  # REMOVED: networking.wireless.iwd.enable = true;
  services.resolved.enable = true;

  # Display & Desktop - Fixed: updated renamed options
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;  # Was: services.xserver.displayManager.gdm.enable
  services.desktopManager.gnome.enable = true;  # Was: services.xserver.desktopManager.gnome.enable
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

  # System Packages - REMOVED: programs.fish.enable (managed by Home Manager)
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
