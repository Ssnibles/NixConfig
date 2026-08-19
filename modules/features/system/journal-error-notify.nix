# =============================================================================
# Boot Journal Error Notification Daemon
# =============================================================================
# Inspects systemd journalctl on login for critical boot errors and displays
# a desktop notification if issues are found. Filters out benign log spam.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, ... }:
    let
      checkBootJournalErrors = pkgs.writeShellScriptBin "check-boot-journal-errors" ''
        # Allow notification daemon time to start up during login session
        sleep 3

        # Filter out known benign log spam (e.g. duplicate dbus names, PAM notices, touchpad probes)
        RAW_ERRORS=$(${pkgs.systemd}/bin/journalctl -b -p 0..3 --no-pager -q | ${pkgs.gnugrep}/bin/grep -v -E "Ignoring duplicate name|gkr-pam: unable to locate daemon control file|bluetoothd.*Failed to set|i2c_hid_acpi.*incomplete report|graphical-session.target|wayland-session.target|systemd-coredump.*vicinae" || true)
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
        description = "Check journalctl for boot errors and trigger desktop notification";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${checkBootJournalErrors}/bin/check-boot-journal-errors";
        };
      };
    };
}
