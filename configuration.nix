{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # --- SYSTEM CORE ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- HARDWARE & FIRMWARE (CRITICAL FOR WIFI) ---
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  # --- NETWORKING (THE INTERNET FIX) ---
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    # iwd is much better at scanning/connecting than the default backend
    wifi.backend = "iwd";
  };

  # DNS fix: ensure NetworkManager talks to systemd-resolved
  services.resolved.enable = true;

  # --- DESKTOP ENVIRONMENTS ---
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  programs.hyprland.enable = true;
  security.polkit.enable = true;

  # --- LOCALIZATION ---
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  # --- AUDIO ---
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  programs.fish.enable = true;

  # --- USER ---
  users.users.josh = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    ghostty
    networkmanagerapplet
  ];

  system.stateVersion = "25.05";
}
