# =============================================================================
# XDG Default Applications
# =============================================================================
# Maps MIME types and URI schemes to default desktop entries.
# These are generated from the programs/packages declared elsewhere in the
# home configuration.
# =============================================================================
{
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        # ── Web / Browser ──────────────────────────────────────────────────────
        "text/html" = "zen.desktop";
        "application/xhtml+xml" = "zen.desktop";
        "application/xml" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/ftp" = "zen.desktop";
        "x-scheme-handler/chrome" = "zen.desktop";
        "application/x-extension-htm" = "zen.desktop";
        "application/x-extension-html" = "zen.desktop";
        "application/x-extension-shtml" = "zen.desktop";
        "application/x-extension-xhtml" = "zen.desktop";
        "application/x-extension-xht" = "zen.desktop";

        # ── PDF / E-book ───────────────────────────────────────────────────────
        "application/pdf" = "zen.desktop";
        "application/x-pdf" = "zen.desktop";
        "application/x-cbz" = "zen.desktop";
        "application/x-cbr" = "zen.desktop";

        # ── Text / Code ────────────────────────────────────────────────────────
        "text/plain" = "neovide.desktop";
        "text/x-log" = "neovide.desktop";
        "text/x-shellscript" = "neovide.desktop";
        "application/x-shellscript" = "neovide.desktop";

        # ── Images ─────────────────────────────────────────────────────────────
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/jpg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/tiff" = "imv.desktop";

        # ── Video ──────────────────────────────────────────────────────────────
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/avi" = "mpv.desktop";
        "video/x-flv" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "video/x-ms-wmv" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";
        "video/ogg" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";

        # ── Audio ────────────────────────────────────────────────────────────────
        "audio/mpeg" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/x-wav" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "audio/x-m4a" = "mpv.desktop";
        "audio/webm" = "mpv.desktop";
        "audio/x-ms-wma" = "mpv.desktop";

        # ── Office Documents ───────────────────────────────────────────────────
        "application/msword" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";
        "application/rtf" = "onlyoffice-desktopeditors.desktop";

        "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
          "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";
        "text/csv" = "onlyoffice-desktopeditors.desktop";
        "application/csv" = "onlyoffice-desktopeditors.desktop";

        "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";

        # ── Chat / Protocols ───────────────────────────────────────────────────
        "x-scheme-handler/discord" = "vesktop.desktop";
      };
    };

    configFile."mimeapps.list".force = true;
    dataFile."applications/mimeapps.list".force = true;
  };
}
