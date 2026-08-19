# =============================================================================
# Plymouth Boot Splash Theme
# =============================================================================
# Catppuccin Mocha themed boot splash screen and silent boot parameter settings.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    {
      boot.plymouth = {
        enable = true;
        theme = "catppuccin-mocha";
        themePackages = [
          (pkgs.catppuccin-plymouth.override {
            variant = "mocha";
          })
        ];
        extraConfig = ''
          [Daemon]
          ShowDelay=0
          DeviceTimeout=8
        '';
      };

      # Prevent Plymouth from waiting indefinitely for quit signal (Ly compatibility)
      systemd.services.plymouth-quit-wait.enable = false;
      systemd.services.display-manager.preStart = "${pkgs.plymouth}/bin/plymouth deactivate && ${pkgs.plymouth}/bin/plymouth quit || true";

      # Silent boot parameters to ensure a smooth graphical Plymouth transition
      boot.consoleLogLevel = 0;
      boot.initrd.verbose = false;
      boot.kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
}
