# Helium browser.
# Helium is Chromium based. This module mirrors the Firefox setup where it can:
# performance flags, privacy policies, force installed extensions, a generated
# theme, and a local startpage.
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.helium;
      cfgAlias = config.features.helium-browser;
      enabled = cfg.enable || cfgAlias.enable;
      isDefaultBrowser = cfg.defaultBrowser || cfgAlias.defaultBrowser;

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

      # Startpage location. The page files are live links, and colours.css is
      # written by Hjem into the same directory.
      startpageDir = "/home/${config.username}/.config/helium/startpage";
      startpageUrl = "file://${startpageDir}/index.html";

      # Chromium has no userChrome.css. A theme extension applies the palette
      # directly and avoids Material You colour derivation.
      hexToRgb =
        hex:
        let
          h = lib.removePrefix "#" hex;
          byte = i: lib.fromHexString (builtins.substring i 2 h);
        in
        [
          (byte 0)
          (byte 2)
          (byte 4)
        ];

      bgRgb = hexToRgb bg;

      # Used only to choose a light or dark color_scheme.
      isDarkTheme =
        (
          0.299 * (builtins.elemAt bgRgb 0)
          + 0.587 * (builtins.elemAt bgRgb 1)
          + 0.114 * (builtins.elemAt bgRgb 2)
        ) < 128;

      themeColors = {
        frame = bgRgb;
        frame_inactive = bgRgb;
        frame_incognito = bgRgb;
        frame_incognito_inactive = bgRgb;
        toolbar = bgRgb;
        tab_text = hexToRgb fg;
        tab_background_text = hexToRgb fgMid;
        tab_background_text_inactive = hexToRgb fgDim;
        bookmark_text = hexToRgb fg;
        toolbar_text = hexToRgb fg;
        toolbar_button_icon = hexToRgb fg;
        omnibox_background = hexToRgb bgRaised;
        omnibox_text = hexToRgb fg;
        ntp_background = hexToRgb bg;
        ntp_text = hexToRgb fg;
        ntp_link = hexToRgb accent;
      };

      themeExtension = pkgs.writeTextDir "manifest.json" (
        builtins.toJSON {
          manifest_version = 3;
          name = "NixConfig ${config.theme.active}";
          version = "1.0";
          theme = {
            colors = themeColors;
            properties.color_scheme = if isDarkTheme then "dark" else "light";
          };
        }
      );

      # Chromium expects one comma separated feature flag.
      enabledFeatures = [
        "TouchpadOverscrollHistoryNavigation"
        # VA-API video decode and encode, including NVIDIA.
        "VaapiVideoDecoder"
        "VaapiVideoEncodeAccelerator"
        "OverlayScrollbar"
      ];

      disabledFeatures = [
        # Remove features we do not use.
        "Translate"
        "OptimizationHints"
        "OptimizationGuideModelDownloading"
        "MediaRouter"
        "GlobalMediaControls"
        "ChromeWhatsNewUI"
        "ChromeLabs"
        "PrivacySandboxSettings4"
        "InterestFeedContentSuggestions"
        "AutofillServerCommunication"
      ];

      # Flags that match the Firefox settings above. The upstream wrapper adds
      # --ozone-platform-hint=auto, so it is not repeated here.
      defaultFlags = [
        # Wayland.
        "--enable-features=${lib.concatStringsSep "," enabledFeatures}"
        "--disable-features=${lib.concatStringsSep "," disabledFeatures}"

        # GPU acceleration.
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-accelerated-video-decode"

        # Disable cosmetic animations.
        "--force-prefers-reduced-motion"

        # Less network prefetching.
        "--dns-prefetch-disable"
        "--disable-preconnect"
        "--no-pings"
        "--no-default-browser-check"

        # Keep the disk cache small.
        "--disk-cache-size=52428800"
      ];

      # Helium only accepts a local new tab page through --custom-ntp.
      startpageFlags = lib.optionals cfg.enableCustomStartpage [
        "--custom-ntp=${cfg.newTabPage}"
      ];

      themeFlags = lib.optionals cfg.enableTheming [ "--load-extension=${themeExtension}" ];

      effectiveFlags =
        defaultFlags
        ++ startpageFlags
        ++ themeFlags
        ++ cfg.flags
        ++ cfg.extraFlags
        ++ cfgAlias.flags
        ++ cfgAlias.extraFlags;

      # Startpage colours. The chrome uses the theme extension above.
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

          /* Shared geometry & motion — consumed by the startpage */
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

      # Extensions from the Chrome Web Store. Helium checks that store for
      # updates to force installed extensions.
      cwsUpdateUrl = "https://clients2.google.com/service/update2/crx";
      extensionCatalogue = {
        "ublock-origin" = {
          id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
          updateUrl = cwsUpdateUrl;
        };
        "bitwarden" = {
          id = "nngceckbapebfimnlniiiahkandclblb";
          updateUrl = cwsUpdateUrl;
        };
        "darkreader" = {
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          updateUrl = cwsUpdateUrl;
        };
        "dark-reader" = {
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          updateUrl = cwsUpdateUrl;
        };
        "sponsorblock" = {
          id = "mnjggcdmjocbbbhaepdhchncahnbgone";
          updateUrl = cwsUpdateUrl;
        };
      };

      resolveExtension =
        name:
        extensionCatalogue.${name} or {
          id = name;
          updateUrl = cwsUpdateUrl;
        };

      autoExtensionSettings = lib.listToAttrs (
        map (
          name:
          let
            ext = resolveExtension name;
          in
          {
            name = ext.id;
            value = {
              installation_mode = "force_installed";
              update_url = ext.updateUrl;
            };
          }
        ) cfg.extensions.packages
      );

      extensionPolicies = lib.optionalAttrs cfg.extensions.enable {
        ExtensionSettings = lib.recursiveUpdate autoExtensionSettings cfg.extensions.extraExtensionSettings;
      };

      # Enterprise policies. Unknown keys are ignored by Chromium. The home
      # button uses the same page as --custom-ntp.
      startupPolicies = lib.optionalAttrs cfg.enableCustomStartpage {
        HomepageIsNewTabPage = true;
        ShowHomeButton = true;
      };

      defaultPolicies = {
        # Startup.
        RestoreOnStartup = 1; # Restore the last session.
        DefaultBrowserSettingEnabled = false;

        # Search.
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        DefaultSearchProviderKeyword = "ddg";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";
        DefaultSearchProviderEncodings = [ "UTF-8" ];
        SearchSuggestEnabled = false;

        # Telemetry and experiments.
        MetricsReportingEnabled = false;
        ChromeVariations = 2; # Disable all variations.
        UserFeedbackAllowed = false;
        CloudReportingEnabled = false;
        SafeBrowsingExtendedReportingEnabled = false;
        UrlKeyedAnonymizedDataCollectionEnabled = false;
        PromotionalTabsEnabled = false;
        BackgroundModeEnabled = false;
        BrowserSignin = 0; # Disable sign in.
        SyncDisabled = true;
        # Keep local Safe Browsing, but skip remote checks.
        SafeBrowsingProtectionLevel = 1;
        HideWebStoreIcon = true;

        # Network and privacy.
        NetworkPredictionOptions = 2; # Never prefetch.
        DnsOverHttpsMode = "off";
        BuiltInDnsClientEnabled = false;
        DNSInterceptionChecksEnabled = false;
        BlockThirdPartyCookies = true;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;
        PrivacySandboxAdMeasurementEnabled = false;
        PrivacySandboxPromptEnabled = false;
        PrivacySandboxRelatedWebsiteSetsEnabled = false;

        # Bitwarden handles passwords and autofill.
        PasswordManagerEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;

        # Deny permissions by default.
        DefaultNotificationsSetting = 2; # Block.
        DefaultGeolocationSetting = 2;
        DefaultSensorsSetting = 2;
        DefaultSerialGuardSetting = 2;
        DefaultWebBluetoothGuardSetting = 2;
        DefaultWebUsbGuardSetting = 2;
        DefaultClipboardSetting = 2;
        DefaultFileSystemReadGuardSetting = 2;
        DefaultFileSystemWriteGuardSetting = 2;
        DefaultLocalFontsSetting = 2;
        DefaultWindowManagementSetting = 2;
        AutoplayAllowed = false;

        # Security.
        HttpsOnlyMode = "force_enabled";
        PromptForDownloadLocation = true;
        DeveloperToolsAvailability = 0; # Allow DevTools.
      };

      effectivePolicies =
        lib.recursiveUpdate (lib.recursiveUpdate defaultPolicies (extensionPolicies // startupPolicies))
          (
            lib.recursiveUpdate cfg.policies (
              lib.recursiveUpdate cfg.extraPolicies (lib.recursiveUpdate cfgAlias.policies cfgAlias.extraPolicies)
            )
          );
    in
    {
      imports = [
        inputs.helium.nixosModules.default
      ];

      options.features.helium = {
        enable = lib.mkEnableOption "Helium Browser";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
          defaultText = lib.literalExpression "inputs.helium.packages.\${pkgs.stdenv.hostPlatform.system}.helium";
          description = "The Helium package to use.";
        };

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set Helium as the default browser in xdg.mime and DEFAULT_BROWSER.";
        };

        enableTheming = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Generate a Chromium theme extension from the active palette and load
            it with --load-extension. Theme-extension colours are applied
            literally, unlike the BrowserThemeColor policy, which runs the seed
            through Material You.
          '';
        };

        enableCustomStartpage = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Materialise the local themed startpage under
            ~/.config/helium/startpage and point the new-tab page (and home
            button) at it. The page files are live symlinks into the checkout
            while colours.css is generated from config.theme.colours.
          '';
        };

        newTabPage = lib.mkOption {
          type = lib.types.str;
          default = startpageUrl;
          defaultText = "file:///home/<user>/.config/helium/startpage/index.html";
          description = ''
            URL used for the new-tab page (passed to --custom-ntp) and the home
            button. Only applied when enableCustomStartpage is true.
          '';
        };

        flags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "--ozone-platform-hint=auto"
            "--enable-features=TouchpadOverscrollHistoryNavigation"
          ];
          description = "Additional command-line flags inserted before extraFlags.";
        };

        extraFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "--ozone-platform-hint=auto"
            "--enable-features=TouchpadOverscrollHistoryNavigation"
          ];
          description = "Additional command-line flags to pass to the Helium wrapper.";
        };

        policies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          example = lib.literalExpression ''
            {
              BrowserSignin = 0;
              PasswordManagerEnabled = false;
            }
          '';
          description = ''
            Chrome Enterprise policies deep-merged over the built-in defaults,
            written to /etc/chromium/policies/managed/helium-nixos.json and
            /etc/helium/policies/managed/helium-nixos.json.
          '';
        };

        extraPolicies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Additional Chrome Enterprise policies deep-merged over policies.";
        };

        extensions = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Force-install the configured Chrome Web Store extensions.";
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "ublock-origin"
              "bitwarden"
              "darkreader"
              "sponsorblock"
            ];
            description = ''
              Extension slugs or raw Chrome Web Store IDs to force-install.
              Known slugs: ublock-origin, bitwarden, darkreader, sponsorblock.
            '';
          };

          extraExtensionSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Additional raw ExtensionSettings merged over the generated force-install entries.";
          };
        };
      };

      # Alias options for convenience (features.helium-browser.*)
      options.features.helium-browser = {
        enable = lib.mkEnableOption "Helium Browser (alias for features.helium)";

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Alias for features.helium.defaultBrowser.";
        };

        flags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Alias for features.helium.flags.";
        };

        extraFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Alias for features.helium.extraFlags.";
        };

        policies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Alias for features.helium.policies.";
        };

        extraPolicies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Alias for features.helium.extraPolicies.";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf enabled {
          programs.helium = {
            enable = true;
            inherit (cfg) package;
            flags = effectiveFlags;
            policies = effectivePolicies;
          };

          features.default-apps.browser = lib.mkIf isDefaultBrowser (lib.mkDefault "helium");
        })

        # Themed startpage. The page files are live links, and colours.css is
        # written by Hjem in the same directory.
        (lib.mkIf (enabled && cfg.enableCustomStartpage) {
          hjem.users."${config.username}" = {
            enable = true;
            files.".config/helium/startpage/colours.css".text = coloursCss;
          };

          nixos.liveLinks."helium-startpage" = {
            source = "${config.nixos.configRepo}/modules/features/apps/helium/startpage";
            target = ".config/helium/startpage";
            contents = true;
          };
        })
      ];
    };
}
