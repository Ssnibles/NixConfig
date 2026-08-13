{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    let
      checkBootJournalErrors = pkgs.writeShellScriptBin "check-boot-journal-errors" ''
        # Give notification daemon time to initialize on login
        sleep 3

        ERRORS=$(${pkgs.systemd}/bin/journalctl -b -p 0..3 --no-pager -q -n 5)
        ERROR_COUNT=$(${pkgs.systemd}/bin/journalctl -b -p 0..3 --no-pager -q | wc -l)

        if [ "$ERROR_COUNT" -gt 0 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            -u critical \
            -i dialog-error \
            -a "Boot Error Checker" \
            "Boot Errors Detected ($ERROR_COUNT)" \
            "Found $ERROR_COUNT error(s) in journalctl during boot. Check 'journalctl -b -p err' for details.\n\nSample errors:\n$ERRORS"
        fi
      '';
    in
    {
      environment.systemPackages = [
        checkBootJournalErrors
        pkgs.libnotify
      ];

      systemd.user.services.check-boot-journal-errors = {
        description = "Check journalctl for boot errors and trigger critical desktop notification";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${checkBootJournalErrors}/bin/check-boot-journal-errors";
        };
      };
    };
}
