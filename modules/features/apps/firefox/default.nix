# Firefox Developer Edition.
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
      inherit (config.theme.colours)
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

      coloursCss = ''
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

          /* Shared geometry & motion — consumed by userChrome + userContent */
          --fx-space-xs: 2px;
          --fx-space-sm: 4px;
          --fx-space-md: 8px;
          --fx-space-lg: 12px;
          --fx-radius-sm: 8px;
          --fx-radius: 12px;
          --fx-radius-lg: 28px;
          --fx-highlight-border-width: 2px;
          --fx-ease: cubic-bezier(0.4, 0, 0.2, 1);
          --fx-transition-fast: 0.12s var(--fx-ease);
          --fx-transition: 0.2s var(--fx-ease);
        }
      '';

      # Turn Nix values into JavaScript literals for user.js.
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

      # Base preferences plus user settings.
      allSettings = cfg.settings // cfg.extraSettings;

      # Base Sidebery settings plus user settings.
      allSideberySettings = cfg.sideberySettings // cfg.extraSideberySettings;

      # Build the user.js contents.
      userJsContent = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: ''user_pref("${name}", ${toJsValue value});'') allSettings
      );

      # Extension IDs and their download URLs.
      extensionCatalogue = {
        "uBlock0@raymondhill.net" =
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        "{3c078156-979c-498b-8990-85f7987dd929}" =
          "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" =
          "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        "addon@darkreader.org" =
          "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        "sponsorBlocker@ajay.app" =
          "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
        "tridactyl.vim.betas.nonewtab@cmcaine.co.uk" =
          "https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi";
      };

      # Short names for the extension IDs.
      extensionAliases = {
        "ublock-origin" = "uBlock0@raymondhill.net";
        "ublock" = "uBlock0@raymondhill.net";
        "sidebery" = "{3c078156-979c-498b-8990-85f7987dd929}";
        "bitwarden" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
        "darkreader" = "addon@darkreader.org";
        "sponsorblock" = "sponsorBlocker@ajay.app";
        "tridactyl" = "tridactyl.vim.betas.nonewtab@cmcaine.co.uk";
        "tridactyl-vim" = "tridactyl.vim.betas.nonewtab@cmcaine.co.uk";
        "tridactyl.vim@cmcaine.co.uk" = "tridactyl.vim.betas.nonewtab@cmcaine.co.uk";
      };

      # Extension lookup by name or ID.
      knownExtensions =
        lib.mapAttrs' (id: url: lib.nameValuePair id { inherit id url; }) extensionCatalogue
        // lib.mapAttrs' (
          alias: id:
          lib.nameValuePair alias {
            inherit id;
            url = extensionCatalogue.${id};
          }
        ) extensionAliases;

      # Build the custom new tab extension.
      customNewTabXpi = pkgs.runCommand "custom-newtab.xpi" { buildInputs = [ pkgs.zip ]; } ''
                mkdir -p tmp_ext
                cp -r ${./startpage}/* tmp_ext/
                cd tmp_ext
                chmod -R +w .
                cat << 'EOF' > colours.css
        ${coloursCss}EOF
                zip -r $out ./*
      '';

      # Discard pinned tabs on startup. Firefox bug 1853047 keeps their content
      # processes alive even when the tabs are restored lazily.
      pinnedUnloadXpi = pkgs.runCommand "pinned-unload.xpi" { buildInputs = [ pkgs.zip ]; } ''
        mkdir -p tmp_ext
        cp -r ${./pinnedunload}/* tmp_ext/
        cd tmp_ext
        chmod -R +w .
        zip -r $out ./*
      '';

      # Extension policy settings.
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
          "pinned-unload@nixconfig.local" = {
            install_url = "file://${pinnedUnloadXpi}";
            installation_mode = "force_installed";
          };
          # Block the normal Tridactyl build so it cannot replace the new tab.
          "tridactyl.vim@cmcaine.co.uk" = {
            installation_mode = "blocked";
          };
        };
    in
    {
      options.features.firefox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
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
              "tridactyl"
            ];
            description = "List of Firefox extension slugs or IDs to auto-install (e.g. ublock-origin, sidebery, bitwarden).";
          };

          extraExtensionSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Additional raw ExtensionSettings for Firefox enterprise policies.";
          };
        };

        sideberySettings = lib.mkOption {
          type = lib.types.attrs;
          default = {
            # Visual style.
            theme = "proton";
            colorScheme = "dark";
            density = "compact";
            fontSize = "m";
            animations = true;
            animationSpeed = "fast";

            # Navigation bar.
            navBarLayout = "horizontal";
            navBarInline = true;
            navBarSide = "left";
            navBtnCount = true;
            hideEmptyPanels = true;
            hideDiscardedTabPanels = false;
            navSwitchPanelsWheel = true;

            # Pinned tabs.
            pinnedTabsPosition = "panel";
            pinnedTabsList = false;
            pinnedNoUnload = false;
            pinnedNoUnloadExplicit = false;
            pinnedForcedDiscard = true;
            tabPinnedMiddleClick = "discard";

            # Tab tree.
            tabsTree = true;
            tabsTreeLimit = "none";
            autoFoldTabs = true;
            autoFoldTabsExcept = "1";
            autoExpandTabs = false;
            rmChildTabs = "folded";
            tabsLvlDots = true;
            discardFolded = true;
            discardFoldedDelay = 0;
            tabsTreeBookmarks = true;
            treeRmOutdent = "branch";

            # Tab behaviour.
            moveNewTab = "last_child";
            moveNewTabParent = "last_child";
            activateLastTabOnPanelSwitching = true;
            activateLastTabOnPanelSwitchingLoadedOnly = true;
            switchPanelAfterSwitchingTab = "always";
            scrollPanelAfterSwitchingTab = "always";
            activateAfterClosing = "next";
            activateAfterClosingNoFolded = true;
            activateAfterClosingNoDiscarded = true;
            scrollThroughTabs = "panel";
            scrollThroughTabsSkipDiscarded = true;
            tabWarmupOnHover = false;
            tabDoubleClick = "close";
            tabsSecondClickActPrev = true;
            tabRmBtn = "hover";
            showNewTabBtns = false;
            previewTabs = true;
            forceDiscard = true;
            tabsReloadLimit = 5;
            tabsReloadLimitNotif = true;

            # Scrollbars and search.
            nativeScrollbars = true;
            nativeScrollbarsThin = true;
            searchBarMode = "dynamic";
            searchPanelSwitch = "same_type";
          };
          description = "Declarative base settings for Sidebery extension managed via Enterprise Policy (managed storage).";
        };

        extraSideberySettings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Additional user preferences to merge into Sidebery managed settings.";
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.either lib.types.bool (lib.types.either lib.types.int lib.types.str)
          );
          default = {
            # Core interface.
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.aboutConfig.showWarning" = false;
            "browser.compactmode.show" = true;
            "browser.uidensity" = 1;
            "browser.tabs.inTitlebar" = 1;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.startup.page" = 3;
            "browser.newtabpage.enabled" = true;
            "browser.urlbar.clickSelectsAll" = true;
            "browser.urlbar.trimHttps" = true;
            "browser.bookmarks.openInTabClosesMenu" = false;
            "findbar.highlightAll" = true;

            # Allow unsigned extensions in Developer Edition.
            "xpinstall.signatures.required" = false;
            "xpinstall.whitelist.required" = false;
            "extensions.autoDisableScopes" = 0;

            # Remove the default home page modules.
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;

            # Performance.
            # Larger font, canvas, and image caches avoid repeated decoding.
            "gfx.content.skia-font-cache-size" = 20;
            "gfx.canvas.accelerated.cache-size" = 32;
            "image.mem.decode_bytes_at_a_time" = 32768;

            # Media cache.
            "media.cache_readahead_limit" = 3600;
            "media.cache_resume_threshold" = 1800;

            # Network buffers.
            "network.buffer.cache.size" = 65535;
            "network.buffer.cache.count" = 48;
            "network.http.max-connections" = 900;
            "network.http.max-persistent-connections-per-server" = 6;
            "network.dnsCacheExpiration" = 3600;
            "dom.ipc.processCount.webIsolated" = 4;
            "accessibility.force_disabled" = 1;
            "media.autoplay.default" = 5;

            # Privacy and security.
            "browser.contentblocking.category" = "strict";
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.cryptomining.enabled" = true;
            "privacy.globalprivacycontrol.enabled" = true;

            # Restore tabs on demand.
            "browser.sessionstore.restore_on_demand" = true;
            "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
            "browser.sessionstore.restore_tabs_lazily" = true;
            "browser.sessionstore.restore_hidden_tabs_on_demand" = true;
            "browser.sessionstore.pause_tab_loading_on_startup" = true;
            "browser.tabs.loadDormantOnSelect" = true;

            # HTTPS only.
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_error_page_user_suggestions" = true;

            # CRLite is faster and more private than OCSP.
            "security.OCSP.enabled" = 0;
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            "security.tls.enable_0rtt_data" = false;
            "security.csp.reporting.enabled" = false;

            # Bitwarden handles password capture.
            "signon.formlessCapture.enabled" = false;
            "signon.privateBrowsingCapture.enabled" = false;
            "network.auth.subresource-http-auth-allow" = 1;

            # Trim cross origin referrers.
            "network.http.referer.XOriginTrimmingPolicy" = 2;

            # Show punycode to stop IDN homograph attacks.
            "network.IDN_show_punycode" = true;

            # Disable scripting in PDFs.
            "pdfjs.enableScripting" = false;

            # Keep local Safe Browsing, but skip remote download checks.
            "browser.safebrowsing.downloads.remote.enabled" = false;

            # Deny notifications and location by default.
            "permissions.default.desktop-notification" = 2;
            "permissions.default.geo" = 2;
            "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";
            "permissions.manager.defaultsUrl" = "";

            # Container tabs.
            "privacy.userContext.ui.enabled" = true;

            # Disable speculative loading to save CPU and network.
            "network.http.speculative-parallel-limit" = 0;
            "network.dns.disablePrefetch" = true;
            "network.dns.disablePrefetchFromHTTPS" = true;
            "network.prefetch-next" = false;
            "network.predictor.enabled" = false;
            "browser.urlbar.speculativeConnect.enabled" = false;
            "browser.places.speculativeConnect.enabled" = false;

            # Keep the cache in RAM to avoid disk writes.
            "browser.cache.disk.enable" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.memory.capacity" = 65536; # 64 MB
            "browser.privatebrowsing.forceMediaMemoryCache" = true;
            "media.memory_cache_max_size" = 65536;
            "browser.sessionstore.interval" = 600000; # Every 10 minutes.
            "browser.sessionstore.max_tabs_undo" = 5;
            "browser.tabs.unloadOnLowMemory" = true;
            "browser.download.start_downloads_in_tmp_dir" = true;

            # Disable telemetry.
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

            # Disable experiments and studies.
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";

            # Remove interface clutter.
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

            # Remove sponsored content.
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;

            # Disable Firefox AI features.
            "browser.ai.control.default" = "blocked";
            "browser.ml.enable" = false;
            "browser.ml.chat.enabled" = false;
            "browser.ml.chat.menu" = false;
            "browser.tabs.groups.smart.enabled" = false;
            "browser.ml.linkPreview.enabled" = false;

            # Instant fullscreen.
            "full-screen-api.transition-duration.enter" = "0 0";
            "full-screen-api.transition-duration.leave" = "0 0";
            "full-screen-api.warning.timeout" = 0;

            # Disable cosmetic animations.
            "toolkit.cosmeticAnimations.enabled" = false;
            "browser.download.animateNotifications" = false;
            "browser.download.manager.addToRecentDocs" = false;
            "browser.download.open_pdf_attachments_inline" = true;

            # Hardware acceleration.
            "media.ffmpeg.vaapi.enabled" = true;

            # Smooth scrolling.
            "general.smoothScroll" = true;

            # Dark mode.
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
              StartPage = "previous-session";
            };
            SearchEngines = {
              Add = [
                {
                  Name = "SearXNG";
                  URLTemplate = "https://search.ssnibles.xyz/search?q={searchTerms}";
                  Method = "GET";
                  IconURL = "https://search.ssnibles.xyz/static/themes/simple/img/favicon.png";
                  Alias = "@searxng";
                  Description = "SearXNG (search.ssnibles.xyz)";
                  SuggestURLTemplate = "https://search.ssnibles.xyz/autocompleter?q={searchTerms}";
                }
              ];
              Default = "SearXNG";
              PreventInstalls = true;
            };
          };
          description = "Firefox enterprise policies.";
        };

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set Firefox as the default web browser for XDG MIME applications.";
        };
      };

      config = lib.mkIf cfg.enable {
        features.default-apps.browser = lib.mkIf (cfg.defaultBrowser && !config.features.helium.enable) (
          lib.mkDefault "firefox"
        );

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "firefox" ''
            exec ${lib.getExe cfg.package} "$@"
          '')
          pkgs.tridactyl-native
        ];

        # Sidebery settings through managed storage. Sidebery merges this over
        # its local storage, so no storage.js seeding is needed.
        environment.etc."firefox/policies/managed/{3c078156-979c-498b-8990-85f7987dd929}.json".text =
          builtins.toJSON
            {
              name = "{3c078156-979c-498b-8990-85f7987dd929}";
              description = "Managed Storage policy for Sidebery extension";
              type = "storage";
              data = {
                settings = allSideberySettings;
              };
            };

        programs.firefox = {
          enable = true;
          package = lib.mkDefault cfg.package;
          # Preferences go to user.js below. Do not also set
          # programs.firefox.preferences: nixpkgs 26.05 turns that into a locked
          # policy, which makes every preference read only in about:config.
          autoConfig = "";
          policies = lib.mkMerge [
            cfg.policies
            {
              ExtensionSettings = autoExtensionSettings;
            }
          ];
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            # Hide the normal Firefox entry so only Developer Edition appears.
            ".local/share/applications/firefox.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Firefox
              NoDisplay=true
            '';

            # Profile setup.
            ".mozilla/firefox/profiles.ini".text = ''
              [Profile0]
              Name=default
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

            # Write the preferences to user.js.
            ".mozilla/firefox/${cfg.profileName}/user.js".text = userJsContent;

            # Theme colours and native messaging.
            ".mozilla/firefox/${cfg.profileName}/chrome/colours.css".text = coloursCss;
            ".mozilla/firefox/${cfg.profileName}/startpage/colours.css".text = coloursCss;
            ".mozilla/native-messaging-hosts/tridactyl.json".source =
              "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
          };

          environment.sessionVariables = {
            MOZ_ALLOW_DOWNGRADE = "1";
          };
        };

        # Live links for the interface files and startpage, so edits apply on
        # refresh or restart without a rebuild.
        nixos.liveLinks = lib.mkMerge [
          {
            "firefox-startpage" = {
              source = "${config.nixos.configRepo}/modules/features/apps/firefox/startpage";
              target = ".mozilla/firefox/${cfg.profileName}/startpage";
              contents = true;
            };
            "firefox-tridactylrc-config" = {
              source = "${config.nixos.configRepo}/modules/features/apps/firefox/tridactylrc";
              target = ".config/tridactyl/tridactylrc";
            };
            "firefox-tridactylrc-home" = {
              source = "${config.nixos.configRepo}/modules/features/apps/firefox/tridactylrc";
              target = ".tridactylrc";
            };
          }
          (lib.mkIf (cfg.enableCustomCss && cfg.userChromeFile != null) {
            "firefox-userchrome" = {
              source =
                if cfg.userChromeFile == ./userChrome.css then
                  "${config.nixos.configRepo}/modules/features/apps/firefox/userChrome.css"
                else
                  cfg.userChromeFile;
              target = ".mozilla/firefox/${cfg.profileName}/chrome/userChrome.css";
            };
          })
          (lib.mkIf (cfg.enableCustomCss && cfg.userContentFile != null) {
            "firefox-usercontent" = {
              source =
                if cfg.userContentFile == ./userContent.css then
                  "${config.nixos.configRepo}/modules/features/apps/firefox/userContent.css"
                else
                  cfg.userContentFile;
              target = ".mozilla/firefox/${cfg.profileName}/chrome/userContent.css";
            };
          })
        ];
      };
    };
}
