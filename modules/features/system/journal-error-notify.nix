# Boot journal error notification.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      noiseEre = lib.escapeShellArg (lib.concatStringsSep "|" config.nixos.journalNoisePatterns);

      checkBootJournalErrors = pkgs.writeShellScriptBin "check-boot-journal-errors" ''
                # Give the notification service time to start.
                sleep 3

                # Ignore known harmless messages.
                RAW_ERRORS=$(${pkgs.systemd}/bin/journalctl -b -p 0..3 --no-pager -q | ${pkgs.gnugrep}/bin/grep -v -E ${noiseEre} || true)
                ERROR_COUNT=$(echo "$RAW_ERRORS" | ${pkgs.gnugrep}/bin/grep -v '^$' | ${pkgs.coreutils}/bin/wc -l)

                if [ "$ERROR_COUNT" -gt 0 ]; then
                  ERRORS=$(echo "$RAW_ERRORS" | ${pkgs.coreutils}/bin/head -n 5)
                  ${pkgs.libnotify}/bin/notify-send \
                    -u critical \
                    -i dialog-error \
                    -a "Boot Error Checker" \
                    "Boot Errors Detected ($ERROR_COUNT)" \
                    "Found $ERROR_COUNT error(s) in journalctl during boot. Check 'journalctl -b -p err' for details.

        Sample errors:
        $ERRORS"
                fi
      '';
    in
    {
      environment.systemPackages = [
        checkBootJournalErrors
      ];

      systemd.user.services.check-boot-journal-errors = {
        description = "Check journalctl for boot errors and trigger desktop notification";
        wantedBy = [ "wayland-session.target" ];
        after = [ "wayland-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${checkBootJournalErrors}/bin/check-boot-journal-errors";
        };
      };
    };
}
