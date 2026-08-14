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
      startpagePort = 9723;
      startpageUrl = "http://127.0.0.1:${toString startpagePort}";
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
        green
        yellow
        red
        orange
        ;

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
        cat << 'EOF' > style.css
:root {
  --fx-bg: #${bg};
  --fx-bg-raised: #${bgRaised};
  --fx-bg-subtle: #${bgSubtle};
  --fx-border: #${border};
  --fx-fg: #${fg};
  --fx-fg-mid: #${fgMid};
  --fx-fg-dim: #${fgDim};
  --fx-accent: #${accent};
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  width: 100%;
  height: 100%;
  background-color: var(--fx-bg);
  color: var(--fx-fg);
  font-family: "Instrument Serif", Georgia, serif;
  overflow: hidden;
}

body {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

.startpage-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  user-select: none;
}

#clock {
  font-size: 11rem;
  font-weight: 400;
  font-style: italic;
  line-height: 1;
  color: var(--fx-fg);
  letter-spacing: -2px;
  margin: 0;
  padding: 0;
  text-shadow: 0 10px 40px rgba(0, 0, 0, 0.4);
  font-variant-numeric: tabular-nums;
}

#date {
  font-size: 2rem;
  font-weight: 400;
  font-style: italic;
  color: var(--fx-accent);
  margin-top: 1rem;
  letter-spacing: 1px;
  opacity: 0.9;
}
EOF
        zip -r $out ./*
      '';

      # Auto-generate extension settings for enterprise policies
      autoExtensionSettings =
        (if cfg.extensions.enable then
          lib.foldl' (
            acc: extName:
            let
              extInfo = knownExtensions.${extName} or {
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
          cfg.extensions.extraExtensionSettings)
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
          default = null;
          description = "Optional path to the userContent.css file to symlink into the Firefox profile.";
        };

        hideHorizontalTabs = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Hide horizontal top tabs (recommended when using vertical tabs like Sidebery).";
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
              "tabliss"
            ];
            description = "List of Firefox extension slugs or IDs to auto-install (e.g. ublock-origin, sidebery, bitwarden, tabliss).";
          };

          extraExtensionSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Additional raw ExtensionSettings for Firefox enterprise policies.";
          };
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str));
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
            "browser.startup.homepage" = "file:///home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/index.html";
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
          type = lib.types.attrsOf (lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str));
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
          files =
            {
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

              # Minimal Startpage HTML with injected system theme colors & Instrument Serif italic font
              ".mozilla/firefox/${cfg.profileName}/startpage/index.html".text = ''
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>New Tab</title>
                  <link rel="preconnect" href="https://fonts.googleapis.com">
                  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                  <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@1&display=swap" rel="stylesheet">
                  <style>
                    :root {
                      --fx-bg: #${bg};
                      --fx-bg-raised: #${bgRaised};
                      --fx-bg-subtle: #${bgSubtle};
                      --fx-border: #${border};
                      --fx-fg: #${fg};
                      --fx-fg-mid: #${fgMid};
                      --fx-fg-dim: #${fgDim};
                      --fx-accent: #${accent};
                    }

                    * {
                      margin: 0;
                      padding: 0;
                      box-sizing: border-box;
                    }

                    html, body {
                      width: 100%;
                      height: 100%;
                      background-color: var(--fx-bg);
                      color: var(--fx-fg);
                      font-family: "Instrument Serif", Georgia, serif;
                      overflow: hidden;
                    }

                    body {
                      display: flex;
                      justify-content: center;
                      align-items: center;
                      min-height: 100vh;
                    }

                    .startpage-container {
                      display: flex;
                      flex-direction: column;
                      align-items: center;
                      justify-content: center;
                      text-align: center;
                      user-select: none;
                    }

                    #clock {
                      font-size: 11rem;
                      font-weight: 400;
                      font-style: italic;
                      line-height: 1;
                      color: var(--fx-fg);
                      letter-spacing: -2px;
                      margin: 0;
                      padding: 0;
                      text-shadow: 0 10px 40px rgba(0, 0, 0, 0.4);
                      font-variant-numeric: tabular-nums;
                    }

                    #date {
                      font-size: 2rem;
                      font-weight: 400;
                      font-style: italic;
                      color: var(--fx-accent);
                      margin-top: 1rem;
                      letter-spacing: 1px;
                      opacity: 0.9;
                    }
                  </style>
                </head>
                <body>
                  <div class="startpage-container">
                    <div id="clock">00:00</div>
                    <div id="date"></div>
                  </div>
                  <script>
                    function updateClock() {
                      const now = new Date();
                      let hours = now.getHours();
                      let minutes = now.getMinutes();

                      hours = hours < 10 ? '0' + hours : hours;
                      minutes = minutes < 10 ? '0' + minutes : minutes;

                      document.getElementById('clock').textContent = hours + ':' + minutes;

                      const options = { weekday: 'long', month: 'long', day: 'numeric' };
                      document.getElementById('date').textContent = now.toLocaleDateString(undefined, options);
                    }

                    updateClock();
                    setInterval(updateClock, 1000);
                  </script>
                </body>
                </html>
              '';
            }
            // (lib.optionalAttrs cfg.enableCustomCss {
              ".mozilla/firefox/${cfg.profileName}/chrome/colors.css".text = ''
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
            })
            // (lib.optionalAttrs cfg.enableCustomCss {
              ".mozilla/firefox/${cfg.profileName}/chrome/userContent.css".text = ''
                @import url('https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@1&display=swap');

                :root {
                  --fx-bg: #${bg};
                  --fx-bg-raised: #${bgRaised};
                  --fx-bg-subtle: #${bgSubtle};
                  --fx-border: #${border};
                  --fx-fg: #${fg};
                  --fx-fg-mid: #${fgMid};
                  --fx-fg-dim: #${fgDim};
                  --fx-accent: #${accent};
                }

                @-moz-document url("about:blank"), url("about:newtab"), url("about:home"), url-prefix("moz-extension://") {
                  html, body {
                    background-color: var(--fx-bg) !important;
                    background-image: none !important;
                    color: var(--fx-fg) !important;
                    font-family: "Instrument Serif", Georgia, serif !important;
                  }

                  .Widgets, .Widgets * {
                    font-family: "Instrument Serif", Georgia, serif !important;
                  }

                  .Time, [class*="Time"], .Widgets .container .Time {
                    font-family: "Instrument Serif", Georgia, serif !important;
                    font-size: 11rem !important;
                    font-weight: 400 !important;
                    font-style: italic !important;
                    line-height: 1 !important;
                    color: var(--fx-fg) !important;
                    letter-spacing: -2px !important;
                    text-shadow: 0 10px 40px rgba(0, 0, 0, 0.4) !important;
                    font-variant-numeric: tabular-nums !important;
                  }

                  .Date, [class*="Date"], .Widgets .container .Date {
                    font-family: "Instrument Serif", Georgia, serif !important;
                    font-size: 2rem !important;
                    font-weight: 400 !important;
                    font-style: italic !important;
                    color: var(--fx-accent) !important;
                    margin-top: 1rem !important;
                    letter-spacing: 1px !important;
                    opacity: 0.9 !important;
                  }
                }
              '';
            });

          environment.sessionVariables = {
            MOZ_ALLOW_DOWNGRADE = "1";
          };

          xdg.mime-apps.default-applications = lib.mkIf cfg.defaultBrowser {
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
          };
        };

        # Symlink userChrome.css directly from NixConfig repo for live-reload
        # (bypasses Nix store so edits take effect on Firefox restart without rebuild)
        # Runs AFTER hjem so it doesn't conflict with hjem's deactivation of old symlinks
        systemd.services.firefox-chrome-symlinks = lib.mkIf (cfg.enableCustomCss && cfg.userChromeFile != null) {
          description = "Symlink Firefox userChrome.css from NixConfig for live-reload";
          after = [ "hjem-activate@${config.username}.service" ];
          wants = [ "hjem-activate@${config.username}.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            mkdir -p /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome
            chown -R ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome
            ln -sfn /home/${config.username}/NixConfig/modules/features/firefox/userChrome.css /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userChrome.css
            chown -h ${config.username}:users /home/${config.username}/.mozilla/firefox/${cfg.profileName}/chrome/userChrome.css
          '';
        };


      };
    };
}
