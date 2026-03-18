# =============================================================================
# Desktop System Configuration
# =============================================================================
# This file contains system-level settings specific to the desktop host.
# It imports hardware-configuration.nix which is auto-generated.
#
# Note on Disko:
#   If hostProfile.useDisko is true, the Disko module will override fileSystems
#   and boot configurations defined in hardware-configuration.nix.
#   If hostProfile.useDisko is false (testing), hardware-configuration.nix is used.
# =============================================================================
{
  config,
  pkgs,
  lib,
  hostProfile,
  stablePkgs,
  ...
}:
{
  # ── Imports ────────────────────────────────────────────────────────────────
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
  ];

  # ── System Identity ────────────────────────────────────────────────────────
  networking.hostName = "desktop";
  system.stateVersion = "25.05";

  # ── Boot Loader ────────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Default kernel (nvidia.nix may override this to stable)
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;

  # ── Networking ─────────────────────────────────────────────────────────────
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # ── Bluetooth ──────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── Power Management ───────────────────────────────────────────────────────
  services.power-profiles-daemon.enable = false;
  powerManagement.cpuFreqGovernor = "performance";
  zramSwap.enable = true;

  # Prevent USB HID devices from suspending
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
  '';

  # ── Display & Desktop ──────────────────────────────────────────────────────
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;
  services.flatpak.enable = true;
  programs.fish.enable = true;

  # ── Audio ──────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ── Key Remapping ──────────────────────────────────────────────────────────
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
      "adbusers"
    ];
  };

  # ── System Packages ────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    iw
  ];

  # ── Locale & Time ──────────────────────────────────────────────────────────
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  # ── Nix Configuration ──────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;
}
