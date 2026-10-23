# Default applications and MIME types.
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
      cfg = config.features.default-apps;

      # Standard web and protocol types.
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

      # Desktop entries for each browser.
      browserDesktopEntries = {
        firefox = [
          "firefox-devedition.desktop"
          "firefox.desktop"
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

      # Media viewers.
      mediaAssociations = {
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/jpg" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/avi" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/mp2t" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "video/x-m4v" = [ "mpv.desktop" ];
        "video/3gpp" = [ "mpv.desktop" ];
        "video/3gpp2" = [ "mpv.desktop" ];
        "video/x-ogm+ogg" = [ "mpv.desktop" ];
        "video/x-theora+ogg" = [ "mpv.desktop" ];
        "video/x-mng" = [ "mpv.desktop" ];
        "application/vnd.apple.mpegurl" = [ "mpv.desktop" ];
        "application/x-mpegURL" = [ "mpv.desktop" ];
        "application/mp4" = [ "mpv.desktop" ];
        "application/ogg" = [ "mpv.desktop" ];
      };

      # Open all text files in the configured editor. Expand text/* here because
      # Hjem writes the user mimeapps.list verbatim and GIO does not expand
      # globs. Browser types stay out of this set.
      editorDesktopEntry = "${cfg.editor}.desktop";

      textMimeTypes = builtins.filter (
        type: lib.hasPrefix "text/" type && !(builtins.elem type webMimeTypes)
      ) (lib.splitString "\n" (builtins.readFile "${pkgs.shared-mime-info}/share/mime/types"));

      editorAssociations = lib.genAttrs (
        textMimeTypes
        ++ [
          # JSON and config types that are not text/*.
          "application/json"
          "application/json5"
          "application/json-patch+json"
          "application/ld+json"
          "application/schema+json"
          "application/toml"
          "application/yaml"
          "application/x-desktop"
          "application/sql"
          "application/x-ipynb+json"
        ]
      ) (_: [ editorDesktopEntry ]);

      allDefaultApplications =
        mediaAssociations
        // editorAssociations
        // browserMimeAssociations
        // fileManagerAssociation
        // cfg.extraAssociations;
    in
    {
      options.features.default-apps = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable centralised default applications and MIME associations.";
        };

        browser = lib.mkOption {
          type = lib.types.enum [
            "firefox"
            "helium"
            "none"
          ];
          default = "none";
          defaultText = lib.literalMD "Derived from `config.features.helium` and `config.features.firefox`";
          description = "Active default web browser.";
        };

        terminal = lib.mkOption {
          type = lib.types.str;
          default = "kitty";
          description = "Default terminal emulator executable.";
        };

        editor = lib.mkOption {
          type = lib.types.str;
          default = "nvim";
          description = "Default text editor executable.";
        };

        fileManager = lib.mkOption {
          type = lib.types.str;
          default = "thunar.desktop";
          description = "Default file manager desktop entry for directory MIME handling.";
        };

        extraAssociations = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example = lib.literalExpression ''
            {
              "inode/directory" = [ "thunar.desktop" ];
            }
          '';
          description = "Additional custom MIME associations merged into default applications.";
        };
      };

      config = lib.mkIf cfg.enable {
        features.default-apps.browser = lib.mkDefault (
          if (config.features.helium.enable or false) && (config.features.helium.defaultBrowser or false) then
            "helium"
          else if
            (config.features.firefox.enable or false) && (config.features.firefox.defaultBrowser or false)
          then
            "firefox"
          else if (config.features.helium.enable or false) then
            "helium"
          else if (config.features.firefox.enable or false) then
            "firefox"
          else
            "none"
        );
        # Session variables.
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

        # System level defaults in /etc/xdg/mimeapps.list.
        xdg.mime = {
          enable = true;
          defaultApplications = allDefaultApplications;
        };

        # User defaults in ~/.config/mimeapps.list.
        hjem.users."${config.username}".xdg.mime-apps.default-applications = allDefaultApplications;
      };
    };
}
