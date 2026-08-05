{ ... }:
{
  nixos.modules.laptop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        ./_hardware-generated.nix
      ] ++ lib.optional (builtins.pathExists ./_installer-options.nix) ./_installer-options.nix;

      # Laptop-specific kernel adjustments
      boot.kernelParams = [
        "ideapad_laptop.allow_v4_dytc=Y"
      ];

      # Load TPM driver early so it's ready before userspace starts
      boot.initrd.kernelModules = [ "tpm_crb" ];

      boot.extraModprobeConfig = ''
        options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
        options rtw89_core disable_ps_mode=y
      '';

      networking.networkmanager = {
        wifi = {
          scanRandMacAddress = false; # avoid scan-triggered disconnects on rtw89
          powersave = false;
        };
        dispatcherScripts = [
          {
            source = pkgs.writeShellScript "wifi-powersave-off" ''
              if [ "$2" = "up" ] && ${pkgs.iw}/bin/iw dev "$1" info >/dev/null 2>&1; then
                ${pkgs.iw}/bin/iw dev "$1" set power_save off
              fi
            '';
            type = "basic";
          }
        ];
      };

      # rtw89-specific quirks for the laptop's Realtek Wi-Fi.
      networking.wireless.iwd.settings = {
        General.DisableANQP = true; # firmware stumbles on ANQP queries
        DriverQuirks.PowerSaveDisable = "rtw89*"; # disable Wi-Fi power save
      };

      services.tlp = {
        enable = true;
        settings = {
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "off";
          USB_AUTOSUSPEND = 1;
          AHCI_RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_AC = "auto";
          PCIE_ASPM_ON_AC = "performance";
          PCIE_ASPM_ON_BAT = "powersave";
          LAPTOP_MODE = 5;
        };
      };

      environment.systemPackages =
        with pkgs.unstable; [
          dfu-util
          emacs-pgtk
          gowall
        ];

      # Define udev rules for DFU devices
      services.udev.extraRules = ''
        # Generic DFU rule (for meshtastic thingy)
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
      '';

      system.stateVersion = "25.05";
    };
}
