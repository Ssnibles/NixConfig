{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    dns = "systemd-resolved";
  };

  networking.wireless.iwd.enable = true;
  services.resolved.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  programs.hyprland.enable = true;
  security.polkit.enable = true;
  services.gvfs.enable = true;

  services.flatpak.enable = true;

  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  programs.fish.enable = true;

  users.users.josh = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "adbusers" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    networkmanagerapplet
  ];

  system.stateVersion = "25.05";
}
