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
      };

      # Prevent Plymouth from waiting indefinitely for a quit signal that 'ly' doesn't send
      systemd.services.plymouth-quit-wait.enable = false;
      systemd.services.display-manager.preStart = "${pkgs.plymouth}/bin/plymouth quit || true";

      # Silent boot parameters to enable a smooth Plymouth transition
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
