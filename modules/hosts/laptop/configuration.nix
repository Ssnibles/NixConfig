{ self, inputs, ... }:
{
  flake.nixosModules.laptopConfiguration =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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
      boot.kernelParams = [
        "ideapad_laptop.allow_v4_dytc=Y"
        "8250.nr_uarts=0" # disable legacy serial ports (save ~2.8s of device timeouts)
      ];
      # Load TPM driver early so it's ready before userspace starts
      boot.initrd.kernelModules = [ "tpm_crb" ];

      networking.hostName = "nixos";

      environment.systemPackages =
        with pkgs;
        [
          usbutils
          dfu-util
          libsecret
          gnupg
          nftables
        ]
        ++ (with pkgs.unstable; [
          emacs-pgtk
          zellij
          gowall
          gimp3
          chatterino7
          mumble
        ]);

      # Define udev rules for DFU devices
      services.udev.extraRules = ''
        # Generic DFU rule (for meshtastic thingy)
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
      '';

      services.upower.enable = true;

      services.displayManager.ly = {
        enable = true;
      };

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

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      security.pam.services.ly.enableGnomeKeyring = true;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.05"; # Did you read the comment?

      swapDevices = [ {
        device = "/swapfile";
        size = 8192;
      } ];

      # Speed up boot
      boot.initrd.systemd.enable = true;
      systemd.services.NetworkManager-wait-online.enable = false;

      # Don't let random-seed refresh block sysinit.target — run it async
      systemd.services.systemd-boot-random-seed = {
        unitConfig.Before = lib.mkForce [ ];
      };
    };
}
