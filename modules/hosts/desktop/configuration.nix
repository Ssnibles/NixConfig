{ self, inputs, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.pipewire
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.development
        self.nixosModules.desktopHardware
        self.nixosModules.niri
        self.nixosModules.contentCreation
        # self.nixosModules.hyprland-noctalia
        self.nixosModules.librewolf
        self.nixosModules.user
      ];

      programs.firefox.enable = true;
      programs.zsh.enable = true;

      # Enable Gnome and GDM for login management and some decent default apps
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        vesktop
        pavucontrol
        keepassxc
        amberol
        chromium
        (element-desktop.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        })
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "nixos"; # Define your hostname.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Enable networking
      networking.networkmanager.enable = true;

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.11"; # Did you read the comment?
    };
}
