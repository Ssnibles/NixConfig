{ self, inputs, ... }:
{
  flake.nixosModules.laptopConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.communications
        self.nixosModules.fonts
        self.nixosModules.pipewire
        self.nixosModules.development
        self.nixosModules.librewolf
        #self.nixosModules.hyprland
        self.nixosModules.niri
        self.nixosModules.user
        # Generated at install time by install.sh (nixos-generate-config).
        # Provides fileSystems and swapDevices for the actual target disk.
        # Leading underscore keeps import-tree from auto-importing it.
        ./_hardware-generated.nix
      ];

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

      # Configure keymap in X11
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        fastfetch
        wget
        git
        self.packages.${pkgs.stdenv.hostPlatform.system}.kitty
        wofi
        waybar
        wl-clipboard
        ripgrep
        emacs-pgtk
        zsh
        zellij
        zip
        unzip
        gnome-keyring
        usbutils
        dfu-util
        libsecret
        seahorse
        gnupg
        gowall
        gimp3
        chatterino7
        mumble
        vesktop
        (element-desktop.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        })
      ];

      programs.zsh.enable = true;

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      virtualisation.docker.enable = true;
      # enable emulation for ARM (for cross-compiling for RaspberryPi)
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # List services that you want to enable:
      services.displayManager.ly = {
        enable = true;
      };
      programs.seahorse.enable = true;
      services.gnome.gnome-keyring.enable = true;
      services.dbus = {
        enable = true;
        packages = [
          pkgs.gnome-keyring
          pkgs.gcr
        ];
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
        experimental-features = [
          "nix-command"
          "flakes"
        ];
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
