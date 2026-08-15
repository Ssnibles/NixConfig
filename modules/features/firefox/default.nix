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
      cfg = config.features.firefox;
      inherit (config.theme.colors)
        bg
        bgRaised
        bgSubtle
        border
        fg
        fgMid
        fgDim
        accent
        teal
        purple
        red
        orange
        ;

      colorsCss = ''
        :root {
          --fx-bg: #${bg};
          --fx-bg-raised: #${bgRaised};
          --fx-bg-subtle: #${bgSubtle};
          --fx-border: #${border};
          --fx-fg: #${fg};
          --fx-fg-mid: #${fgMid};
          --fx-fg-dim: #${fgDim};
          --fx-accent: #${accent};
          --fx-teal: #${teal};
          --fx-purple: #${purple};
          --fx-red: #${red};
          --fx-orange: #${orange};
        }
      '';

      # Map Nix primitive values to JS literals for user.js
      toJsValue =
        val:
        if builtins.isBool val then
          (if val then "true" else "false")
        else if builtins.isInt val then
          toString val
        else if builtins.isString val then
          ''"${val}"''
        else
          ''"${toString val}"'';

      # Combine base default about:config preferences with user extra settings
      allSettings = cfg.settings // cfg.extraSettings;

      # Generate user.js file contents: user_pref("key", val);
      userJsContent = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: ''user_pref("${name}", ${toJsValue value});'') allSettings
      );

      # Known extension mappings (name/slug -> ID & download URL)
      knownExtensions = {
        "ublock-origin" = {
          id = "uBlock0@raymondhill.net";
          url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "ublock" = {
          id = "uBlock0@raymondhill.net";
          url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          id = "uBlock0@raymondhill.net";
          url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "sidebery" = {
          id = "{3c078156-979c-498b-8990-85f7987dd929}";
          url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        };
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          id = "{3c078156-979c-498b-8990-85f7987dd929}";
          url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        };
        "bitwarden" = {
          id = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
          url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          id = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
          url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "darkreader" = {
          id = "addon@darkreader.org";
          url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        };
        "sponsorblock" = {
          id = "sponsorBlocker@ajay.app";
          url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
        };
        "tabliss" = {
          id = "tabliss@tabliss.io";
          url = "https://addons.mozilla.org/firefox/downloads/latest/tabliss/latest.xpi";
        };
        "tabliss@tabliss.io" = {
          id = "tabliss@tabliss.io";
          url = "https://addons.mozilla.org/firefox/downloads/latest/tabliss/latest.xpi";
        };
      };

      # Build custom New Tab WebExtension package (.xpi)
      customNewTabXpi = pkgs.runCommand "custom-newtab.xpi" { buildInputs = [ pkgs.zip ]; } ''
                mkdir -p tmp_ext
                cp -r ${./startpage}/* tmp_ext/
                cd tmp_ext
                chmod -R +w .
                cat << 'EOF' > colors.css
        ${colorsCss}EOF
                zip -r $out ./*
      '';

      # Auto-generate extension settings for enterprise policies
      autoExtensionSettings =
        (
          if cfg.extensions.enable then
            lib.foldl' (
              acc: extName:
              let
                extInfo =
                  knownExtensions.${extName} or {
                    id = extName;
                    url = "https://addons.mozilla.org/firefox/downloads/latest/${extName}/latest.xpi";
                  };
              in
              acc
              // {
                "${extInfo.id}" = {
                  install_url = extInfo.url;
                  installation_mode = "force_installed";
                };
              }
            ) cfg.extensions.extraExtensionSettings cfg.extensions.packages
          else
            cfg.extensions.extraExtensionSettings
        )
        // {
          "custom-newtab@nixconfig.local" = {
            install_url = "file://${customNewTabXpi}";
            installation_mode = "force_installed";
          };
        };
    in
    {
      options.features.firefox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the custom Firefox module.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.firefox-devedition;
          description = "Firefox package to install.";
        };

        profileName = lib.mkOption {
          type = lib.types.str;
          default = "default";
          description = "Name of the Firefox profile to configure.";
        };

        enableCustomCss = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enables custom CSS stylesheets (toolkit.legacyUserProfileCustomizations.stylesheets = true).";
        };

        userChromeFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = ./userChrome.css;
          description = "Path to the userChrome.css file to symlink into the Firefox profile.";
        };

        userContentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = ./userContent.css;
          description = "Path to the userContent.css file to symlink into the Firefox profile.";
        };

        extensions = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to automatically install configured Firefox extensions.";
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "ublock-origin"
              "sidebery"
            ];
            description = "List of Firefox extension slugs or IDs to auto-install (e.g. ublock-origin, sidebery, bitwarden).";
          };

          extraExtensionSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Additional raw ExtensionSettings for Firefox enterprise policies.";
          };
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str)
          );
          default = {
            # ==============================================================
            # CORE UI & EXPERIENCE
            # ==============================================================
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.aboutConfig.showWarning" = false;
            "browser.compactmode.show" = true;
            "browser.uidensity" = 1;
            "browser.tabs.inTitlebar" = 1;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.startup.homepage" =
              "file:///home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/index.html";
            "browser.startup.page" = 1;
            "browser.newtabpage.enabled" = true;
            "browser.urlbar.clickSelectsAll" = true;
            "browser.urlbar.trimHttps" = true;
            "browser.urlbar.untrimOnUserInteraction.featureGate" = true;
            "browser.bookmarks.openInTabClosesMenu" = false;
            "findbar.highlightAll" = true;

            # Allow unsigned extensions in Developer Edition
            "xpinstall.signatures.required" = false;
            "xpinstall.whitelist.required" = false;
            "extensions.autoDisableScopes" = 0;

            # Disable default Firefox Home / Activity Stream elements
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;

            # ==============================================================
            # FASTFOX — RENDERING & NETWORK PERFORMANCE
            # ==============================================================
            # Font/canvas/image caches — larger = fewer re-decodes
            "gfx.content.skia-font-cache-size" = 20;
            "gfx.canvas.accelerated.cache-size" = 512;
            "image.mem.decode_bytes_at_a_time" = 32768;

            # JIT — compile hot functions sooner for snappier JS
            "javascript.options.baselinejit.threshold" = 50;

            # Batch content paint notifications — fewer layout reflows
            "content.notify.interval" = 100000;

            # Media cache — better video/audio buffering
            "media.cache_readahead_limit" = 3600;
            "media.cache_resume_threshold" = 1800;

            # Network buffer tuning
            "network.buffer.cache.size" = 65535;
            "network.buffer.cache.count" = 48;
            "network.http.max-connections" = 1800;
            "network.http.max-persistent-connections-per-server" = 10;
            "network.http.max-urgent-start-excessive-connections-per-host" = 5;
            "network.http.request.max-start-delay" = 5;
            "network.dnsCacheExpiration" = 3600;

            # ==============================================================
            # PRIVACY & SECURITY
            # ==============================================================
            "browser.contentblocking.category" = "strict";
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.cryptomining.enabled" = true;
            "privacy.globalprivacycontrol.enabled" = true;

            # HTTPS-only mode
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_error_page_user_suggestions" = true;

            # OCSP off — CRLite is faster and more private
            "security.OCSP.enabled" = 0;
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            "security.tls.enable_0rtt_data" = false;
            "security.csp.reporting.enabled" = false;

            # Disable built-in password capture (Bitwarden handles this)
            "signon.formlessCapture.enabled" = false;
            "signon.privateBrowsingCapture.enabled" = false;
            "network.auth.subresource-http-auth-allow" = 1;

            # Trim cross-origin referers for privacy
            "network.http.referer.XOriginTrimmingPolicy" = 2;

            # Show punycode to prevent IDN homograph attacks
            "network.IDN_show_punycode" = true;

            # Disable PDF scripting (security)
            "pdfjs.enableScripting" = false;

            # Safe browsing — keep local but disable remote download checks
            "browser.safebrowsing.downloads.remote.enabled" = false;

            # Default-deny notifications and geolocation
            "permissions.default.desktop-notification" = 2;
            "permissions.default.geo" = 2;
            "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";
            "permissions.manager.defaultsUrl" = "";

            # Container tabs
            "privacy.userContext.ui.enabled" = true;

            # ==============================================================
            # SPECULATIVE LOADING — DISABLE (saves CPU, network, privacy)
            # ==============================================================
            "network.http.speculative-parallel-limit" = 0;
            "network.dns.disablePrefetch" = true;
            "network.dns.disablePrefetchFromHTTPS" = true;
            "network.prefetch-next" = false;
            "network.predictor.enabled" = false;
            "browser.urlbar.speculativeConnect.enabled" = false;
            "browser.places.speculativeConnect.enabled" = false;

            # ==============================================================
            # DISK AVOIDANCE — RAM CACHE (faster, less SSD wear)
            # ==============================================================
            "browser.cache.disk.enable" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.memory.capacity" = 262144; # 256MB RAM cache
            "browser.privatebrowsing.forceMediaMemoryCache" = true;
            "media.memory_cache_max_size" = 65536;
            "browser.sessionstore.interval" = 600000; # 10min session saves
            "browser.sessionstore.max_tabs_undo" = 5;
            "browser.tabs.unloadOnLowMemory" = true;
            "browser.download.start_downloads_in_tmp_dir" = true;

            # ==============================================================
            # TELEMETRY — COMPLETE DISABLE
            # ==============================================================
            "datareporting.policy.dataSubmissionEnabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.usage.uploadEnabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.coverage.opt-out" = true;
            "toolkit.coverage.endpoint.base" = "";
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.tabs.crashReporting.sendReport" = false;

            # ==============================================================
            # EXPERIMENTS & STUDIES — DISABLE
            # ==============================================================
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";

            # ==============================================================
            # PESKYFOX — UI DECLUTTER & ANNOYANCE REMOVAL
            # ==============================================================
            "extensions.getAddons.showPane" = false;
            "extensions.getAddons.cache.enabled" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
            "browser.preferences.moreFromMozilla" = false;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.aboutwelcome.enabled" = false;
            "browser.uitour.enabled" = false;
            "browser.search.update" = false;
            "browser.search.suggest.enabled" = false;
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.groupLabels.enabled" = false;
            "browser.urlbar.trending.featureGate" = false;
            "browser.formfill.enable" = false;

            # Kill sponsored content
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;

            # Disable Firefox AI features
            "browser.ai.control.default" = "blocked";
            "browser.ml.enable" = false;
            "browser.ml.chat.enabled" = false;
            "browser.ml.chat.menu" = false;
            "browser.tabs.groups.smart.enabled" = false;
            "browser.ml.linkPreview.enabled" = false;

            # Instant fullscreen transitions
            "full-screen-api.transition-duration.enter" = "0 0";
            "full-screen-api.transition-duration.leave" = "0 0";
            "full-screen-api.warning.timeout" = 0;

            # Disable cosmetic UI animations (reduces CPU)
            "toolkit.cosmeticAnimations.enabled" = false;
            "browser.download.animateNotifications" = false;
            "browser.download.manager.addToRecentDocs" = false;
            "browser.download.open_pdf_attachments_inline" = true;

            # ==============================================================
            # GRAPHICS & HARDWARE ACCELERATION
            # ==============================================================
            "media.ffmpeg.vaapi.enabled" = true;
            "gfx.webrender.all" = true;
            "layers.acceleration.force-enabled" = true;
            "layout.css.backdrop-filter.enabled" = true;
            "svg.context-properties.content.enabled" = true;

            # Smooth scrolling
            "general.smoothScroll" = true;

            # ==============================================================
            # DARK MODE & THEME
            # ==============================================================
            "ui.systemUsesDarkTheme" = 1;
            "layout.css.prefers-color-scheme.content-override" = 0;
            "browser.in-content.dark-mode" = true;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
            "browser.privateWindowSeparation.enabled" = false;
            "sidebar.revamp" = false;
            "sidebar.verticalTabs" = false;
          };
          description = "Base preferences automatically written to about:config / user.js.";
        };

        extraSettings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str)
          );
          default = { };
          description = "Additional user preferences to merge into about:config / user.js.";
        };

        policies = lib.mkOption {
          type = lib.types.attrs;
          default = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            Homepage = {
              URL = "file:///home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/index.html";
              Locked = true;
              StartPage = "homepage";
            };
            SearchEngines = {
              Default = "DuckDuckGo";
              PreventInstalls = true;
            };
          };
          description = "Firefox enterprise policies.";
        };

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set Firefox as the default web browser for XDG MIME applications.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "firefox" ''
            exec ${cfg.package}/bin/firefox-devedition "$@"
          '')
        ];

        programs.firefox = {
          enable = true;
          package = lib.mkDefault cfg.package;
          preferences = lib.mkDefault allSettings;
          autoConfig = "";
          policies = lib.mkMerge [
            cfg.policies
            {
              ExtensionSettings = autoExtensionSettings;
            }
          ];
        };

        hjem.users."${config.username}" = {
          files = {
            # Hide standard firefox.desktop launcher entry so only Firefox Developer Edition appears
            ".local/share/applications/firefox.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Firefox
              NoDisplay=true
            '';

            # Profile initialization config
            ".mozilla/firefox/profiles.ini".text = ''
              [Profile0]
              Name=${cfg.profileName}
              IsRelative=1
              Path=${cfg.profileName}
              Default=1

              [Profile1]
              Name=dev-edition-default
              IsRelative=1
              Path=${cfg.profileName}
              Default=1

              [General]
              StartWithLastProfile=1
              Version=2
            '';

            ".mozilla/firefox/installs.ini".text = ''
              [Default]
              Default=${cfg.profileName}
              Locked=0
            '';

            # Automatically write preferences to about:config via user.js
            ".mozilla/firefox/${cfg.profileName}/user.js".text = userJsContent;
          };

          environment.sessionVariables = {
            MOZ_ALLOW_DOWNGRADE = "1";
          };

          xdg.mime-apps.default-applications = {
            "text/html" = [ "firefox-devedition.desktop" ];
            "application/xhtml+xml" = [ "firefox-devedition.desktop" ];
            "application/xml" = [ "firefox-devedition.desktop" ];
            "x-scheme-handler/http" = [ "firefox-devedition.desktop" ];
            "x-scheme-handler/https" = [ "firefox-devedition.desktop" ];
            "x-scheme-handler/ftp" = [ "firefox-devedition.desktop" ];
            "x-scheme-handler/chrome" = [ "firefox-devedition.desktop" ];
            "application/x-extension-htm" = [ "firefox-devedition.desktop" ];
            "application/x-extension-html" = [ "firefox-devedition.desktop" ];
            "application/x-extension-shtml" = [ "firefox-devedition.desktop" ];
            "application/x-extension-xhtml" = [ "firefox-devedition.desktop" ];
            "application/x-extension-xht" = [ "firefox-devedition.desktop" ];
            "application/pdf" = [ "org.pwmt.zathura.desktop" ];
            "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
          };
        };

        # Direct repository symlinks for live-reloading UI customization (userChrome, userContent, startpage)
        # Bypasses Nix store so edits in NixConfig take effect immediately on Firefox refresh/restart
        system.activationScripts.firefox-config = ''
          mkdir -p /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome
          chown -R ${config.username}:users /home/${config.username}/.mozilla

          # Dynamic theme CSS variables
          cat << 'EOF' > /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/colors.css
          ${colorsCss}
          EOF
          chown ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/colors.css

          ${lib.optionalString (cfg.enableCustomCss && cfg.userChromeFile != null) ''
            ln -sfn /home/${config.username}/NixConfig/modules/features/firefox/userChrome.css /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userChrome.css
            chown -h ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userChrome.css
          ''}
          ${lib.optionalString (cfg.enableCustomCss && cfg.userContentFile != null) ''
            ln -sfn /home/${config.username}/NixConfig/modules/features/firefox/userContent.css /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userContent.css
            chown -h ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userContent.css
          ''}

          # Symlink startpage directory for live reloading
          rm -rf /home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage
          ln -sfn /home/${config.username}/NixConfig/modules/features/firefox/startpage /home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage
          chown -h ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage

          cat << 'EOF' > /home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/colors.css
          ${colorsCss}
          EOF
          chown ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/colors.css
        '';
      };
    };
}
