{ self, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { pkgs, lib, config, ... }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.bluetooth
        self.nixosModules.startup
        self.nixosModules.cli
        self.nixosModules.pipewire
        self.nixosModules.fonts
        self.nixosModules.gaming
        self.nixosModules.nvidia
        self.nixosModules.media
        self.nixosModules.development
        self.nixosModules.communications
        self.nixosModules.contentCreation
        self.nixosModules.hyprland-noctalia
        self.nixosModules.mangowc
        self.nixosModules.niri
        self.nixosModules.foot
        self.nixosModules.kitty
        self.nixosModules.podman-vm
        self.nixosModules.qutebrowser
        self.nixosModules.zen-browser
        self.nixosModules.neovim
        self.nixosModules.user
        # Generated at install time by install.sh (nixos-generate-config).
        # Provides fileSystems and swapDevices for the actual target disk.
        # Leading underscore keeps import-tree from auto-importing it.
        ./_hardware-generated.nix
      ];

      # Bootloader
      boot.loader.limine.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.systemd.enable = true;
      boot.initrd.compressor = "zstd";
      boot.initrd.compressorArgs = [ "-1" ];

      boot.kernelModules = [ "btusb" ];

      boot.kernelParams = [
        "mitigations=off"
        "8250.nr_uarts=0"
        "noatime"
      ];
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 200;
      };

      # Limit journal size to 100M
      services.journald.extraConfig = ''
        SystemMaxUse=100M
      '';

      # Unblock Bluetooth at boot — asus_wmi soft-blocks the adapter
      systemd.services.unblock-bluetooth = {
        description = "Unblock Bluetooth rfkill";
        after = [ "sysinit.target" ];
        before = [ "bluetooth.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = 5;
        };
        script = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };

      hardware.logitech.wireless.enable = true;

      # Don't block boot on network online
      systemd.services.NetworkManager-wait-online.enable = false;

      # Don't let random-seed refresh block sysinit.target — run it async
      systemd.services.systemd-boot-random-seed = {
        unitConfig.Before = lib.mkForce [ ];
      };

      # Reduce writes with noatime
      fileSystems."/" = {
        options = [ "noatime" ];
      };

      swapDevices = [
        {
          device = "/swapfile";
          size = 8192;
        }
      ];

      environment.systemPackages = with pkgs.unstable; [
        keepassxc
        amberol
        chromium
      ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Enable ly for login management
      services.displayManager.ly.enable = true;
      security.pam.services.ly.enableGnomeKeyring = true;

      services.upower.enable = true;

      # Swap Caps Lock and Escape via udev hwdb (kernel-level, no daemon needed)
      services.udev.extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svn*:pn*:pvr*
         KEYBOARD_KEY_3a=esc
         KEYBOARD_KEY_01=capslock
        evdev:input:b*v*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_70029=capslock
      '';

      networking.hostName = "nixos";

      # Open ports in the firewall.
      networking.firewall.allowedTCPPorts = [ 5353 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];

      system.stateVersion = "25.11";
    };
}
