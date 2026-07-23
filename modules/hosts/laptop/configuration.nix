{ self, inputs, ... }:
{
  flake.nixosModules.laptopConfiguration =
    { pkgs, lib, config, ... }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.startup
        self.nixosModules.cli
        self.nixosModules.communications
        self.nixosModules.fonts
        self.nixosModules.pipewire
        self.nixosModules.development
        self.nixosModules.mangowc
        self.nixosModules.zen-browser
        self.nixosModules.neovim
        self.nixosModules.user
        self.nixosModules.gaming
        self.nixosModules.media
        self.nixosModules.foot
        self.nixosModules.kitty

        # Generated at install time by install.sh
        # Leading underscore keeps import-tree from auto-importing it.
        ./_hardware-generated.nix
      ];

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Use latest kernel
      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "nixos";

      environment.systemPackages =
        with pkgs;
        [
          usbutils
          dfu-util
          libsecret
          gnupg
        ]
        ++ (with pkgs.unstable; [
          emacs-pgtk
          zellij
          gowall
          gimp3
          chatterino7
          mumble
        ]);

      services.displayManager.ly = {
        enable = true;
      };
      # Define udev rules for DFU devices
      services.udev.extraRules = ''
        # Generic DFU rule (for meshtastic thingy)
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
      '';

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      security.pam.services.ly.enableGnomeKeyring = true;

      nix.settings = {
        substituters = [
          "https://cache.nixos.org/"
          "https://cache.garnix.io"
        ];
        trusted-public-keys = [
          # Default NixOS cache key
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          # Garnix cache key
          "cache.garnix.io:Lf0liRJ2oT5zekG0arzGcHtrIfuVjGrAG1MxRCBuFlA="
        ];
        download-buffer-size = 524288000;
      };

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.05"; # Did you read the comment?

      # swapDevices = [
      #   {
      #     device = "/dev/disk/by-label/swap"; # Or "/dev/sda2"
      #   }
      # ];
    };
}
