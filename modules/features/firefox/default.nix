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
        "new-tab-override" = {
          id = "newtaboverride@agenedia.com";
          url = "https://addons.mozilla.org/firefox/downloads/latest/new-tab-override/latest.xpi";
        };
        "newtaboverride@agenedia.com" = {
          id = "newtaboverride@agenedia.com";
          url = "https://addons.mozilla.org/firefox/downloads/latest/new-tab-override/latest.xpi";
        };
      };

      # Auto-generate extension settings for enterprise policies
      autoExtensionSettings =
        if cfg.extensions.enable then
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
          cfg.extensions.extraExtensionSettings;
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
          default = pkgs.firefox;
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
              "new-tab-override"
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
          type = lib.types.attrsOf (lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str));
          default = {
            # Stylesheets / Custom CSS support
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # about:config UI & experience
            "browser.aboutConfig.showWarning" = false;
            "browser.compactmode.show" = true;
            "browser.uidensity" = 1;
            "browser.tabs.inTitlebar" = 1;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.startup.homepage" = "file:///home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/index.html";
            "browser.startup.page" = 1;
            "browser.newtabpage.enabled" = false;
            "browser.tabs.unloadOnLowMemory" = true;
            "browser.sessionstore.interval" = 600000;

            # Privacy & Security
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.cryptomining.enabled" = true;
            "privacy.globalprivacycontrol.enabled" = true;

            # Graphics & Hardware Acceleration
            "media.ffmpeg.vaapi.enabled" = true;
            "gfx.webrender.all" = true;
            "layers.acceleration.force-enabled" = true;
            "layout.css.backdrop-filter.enabled" = true;
            "svg.context-properties.content.enabled" = true;

            # Smooth scrolling
            "general.smoothScroll" = true;

            # Force Dark Mode UI & WebExtension Popups/Sidebars (e.g. Sidebery)
            "ui.systemUsesDarkTheme" = 1;
            "layout.css.prefers-color-scheme.content-override" = 0;
            "browser.in-content.dark-mode" = true;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
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
            "3rdparty" = {
              Extensions = {
                "newtaboverride@agenedia.com" = {
                  type = "custom_url";
                  url = "file:///home/${config.username}/.mozilla/firefox/${cfg.profileName}/startpage/index.html";
                  focus_website = true;
                };
              };
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
        environment.systemPackages = [ cfg.package ];

        programs.firefox = {
          enable = true;
          package = lib.mkDefault cfg.package;
          preferences = lib.mkDefault allSettings;
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
              # Profile initialization config
              ".mozilla/firefox/profiles.ini".text = ''
                [Profile0]
                Name=${cfg.profileName}
                IsRelative=1
                Path=${cfg.profileName}
                Default=1

                [General]
                StartWithLastProfile=1
                Version=2
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
                :root {
                  --fx-bg: #${bg};
                  --fx-fg: #${fg};
                }

                @-moz-document url("about:blank"), url("about:newtab"), url("about:home") {
                  body, html {
                    background-color: var(--fx-bg) !important;
                    color: var(--fx-fg) !important;
                  }
                }
              '';
            });

          xdg.mime-apps.default-applications = lib.mkIf cfg.defaultBrowser {
            "text/html" = [ "firefox.desktop" ];
            "application/xhtml+xml" = [ "firefox.desktop" ];
            "application/xml" = [ "firefox.desktop" ];
            "x-scheme-handler/http" = [ "firefox.desktop" ];
            "x-scheme-handler/https" = [ "firefox.desktop" ];
            "x-scheme-handler/ftp" = [ "firefox.desktop" ];
            "x-scheme-handler/chrome" = [ "firefox.desktop" ];
            "application/x-extension-htm" = [ "firefox.desktop" ];
            "application/x-extension-html" = [ "firefox.desktop" ];
            "application/x-extension-shtml" = [ "firefox.desktop" ];
            "application/x-extension-xhtml" = [ "firefox.desktop" ];
            "application/x-extension-xht" = [ "firefox.desktop" ];
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
