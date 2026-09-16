# =============================================================================
# Default Applications & MIME Handlers Feature
# =============================================================================
# Centralized single source of truth for default system applications, session
# environment variables, and declarative XDG MIME associations via Hjem.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.default-apps;

      # Standard web and protocol MIME types
      webMimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/rss+xml"
        "application/rdf+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chrome"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-xht"
      ];

      # Desktop entries for known browsers
      browserDesktopEntries = {
        firefox = [
          "firefox-devedition.desktop"
          "firefox.desktop"
        ];
        zen = [
          "zen-twilight.desktop"
          "zen.desktop"
        ];
        helium = [ "helium.desktop" ];
      };

      activeBrowserEntries = browserDesktopEntries.${cfg.browser} or [ ];

      browserMimeAssociations = lib.optionalAttrs (activeBrowserEntries != [ ]) (
        lib.genAttrs webMimeTypes (_: activeBrowserEntries)
      );

      fileManagerAssociation = lib.optionalAttrs (cfg.fileManager != "none") {
        "inode/directory" = [ cfg.fileManager ];
      };

      # Combined MIME associations for default-apps
      allDefaultApplications =
        browserMimeAssociations
        // fileManagerAssociation
        // cfg.extraAssociations;
    in
    {
      options.features.default-apps = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable centralized default applications and MIME associations.";
        };

        browser = lib.mkOption {
          type = lib.types.enum [
            "firefox"
            "zen"
            "helium"
            "none"
          ];
          default =
            if (config.features.helium.enable or false) && (config.features.helium.defaultBrowser or false) then
              "helium"
            else if (config.features.zen-browser.enable or false) then
              "zen"
            else if (config.features.firefox.enable or false) && (config.features.firefox.defaultBrowser or false) then
              "firefox"
            else if (config.features.helium.enable or false) then
              "helium"
            else if (config.features.firefox.enable or false) then
              "firefox"
            else
              "none";
          description = "Active default web browser.";
        };

        terminal = lib.mkOption {
          type = lib.types.str;
          default = "foot";
          description = "Default terminal emulator executable.";
        };

        editor = lib.mkOption {
          type = lib.types.str;
          default = "nvim";
          description = "Default text editor executable.";
        };

        fileManager = lib.mkOption {
          type = lib.types.str;
          default = "yazi.desktop";
          description = "Default file manager desktop entry for directory MIME handling.";
        };

        extraAssociations = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example = lib.literalExpression ''
            {
              "inode/directory" = [ "yazi.desktop" ];
            }
          '';
          description = "Additional custom MIME associations merged into default applications.";
        };
      };

      config = lib.mkIf cfg.enable {
        # ── Global Session Variables ──────────────────────────────────────────
        environment.sessionVariables = lib.mkMerge [
          {
            EDITOR = cfg.editor;
            VISUAL = cfg.editor;
            TERMINAL = cfg.terminal;
          }
          (lib.mkIf (cfg.browser != "none") {
            BROWSER = cfg.browser;
            DEFAULT_BROWSER = cfg.browser;
          })
        ];

        # ── System-level XDG MIME defaults (/etc/xdg/mimeapps.list) ───────────
        xdg.mime = {
          enable = true;
          defaultApplications = allDefaultApplications;
        };

        # ── User-level XDG MIME defaults (~/.config/mimeapps.list via Hjem) ───
        hjem.users."${config.username}".xdg.mime-apps.default-applications = allDefaultApplications;
      };
    };
}
