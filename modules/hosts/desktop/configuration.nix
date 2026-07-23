{ self, inputs, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { pkgs, lib, ... }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.startup
        self.nixosModules.cli
        self.nixosModules.pipewire
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.development
        self.nixosModules.communications
        self.nixosModules.contentCreation
        self.nixosModules.hyprland-noctalia
        self.nixosModules.zen-browser
        self.nixosModules.neovim
        self.nixosModules.user
        # Generated at install time by install.sh (nixos-generate-config).
        # Provides fileSystems and swapDevices for the actual target disk.
        # Leading underscore keeps import-tree from auto-importing it.
        ./_hardware-generated.nix
      ];

      # Enable Gnome and GDM for login management and some decent default apps
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      environment.systemPackages = with pkgs.unstable; [
        keepassxc
        amberol
        chromium
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

      networking.hostName = "nixos";

      # Open ports in the firewall.
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      system.stateVersion = "25.11";
    };
}
