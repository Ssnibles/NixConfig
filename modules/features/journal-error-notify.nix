{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    let
      checkBootJournalErrors = pkgs.writeShellScriptBin "check-boot-journal-errors" ''
        # Give notification daemon time to initialize on login
        sleep 3

        # Filter out benign dbus-broker duplicate service name warnings, gkr-pam initial auth notice, early bluetoothd init warnings, and touchpad early probe warnings
        RAW_ERRORS=$(${pkgs.systemd}/bin/journalctl -b -p 0..3 --no-pager -q | ${pkgs.gnugrep}/bin/grep -v -E "Ignoring duplicate name|gkr-pam: unable to locate daemon control file|bluetoothd.*Failed to set|i2c_hid_acpi.*incomplete report|systemd-coredump.*vicinae" || true)
        ERROR_COUNT=$(echo "$RAW_ERRORS" | ${pkgs.gnugrep}/bin/grep -v '^$' | wc -l)

        if [ "$ERROR_COUNT" -gt 0 ]; then
          ERRORS=$(echo "$RAW_ERRORS" | head -n 5)
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
