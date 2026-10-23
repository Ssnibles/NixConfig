# Helium Browser Feature
# Helium Browser (Chromium-based) installation, Chrome Enterprise policies,
# command-line flags, force-installed Web Store extensions, and default
# xdg-open MIME associations via the oxcl/nix-flake-helium-browser flake.
#
# This module deliberately mirrors the behaviour/theming of
# modules/features/apps/firefox/default.nix as closely as Chromium allows:
#   * FastFox performance tuning        -> GPU/network/cache flags + policies
#   * Privacy, telemetry & studies off  -> Enterprise policies + flags
#   * PeskyFox UI declutter / AI off    -> policies + --disable-features flags
#   * Theme palette                     -> generated theme extension (literal colours)
#   * Custom startpage / new tab        -> live-linked startpage + --custom-ntp flag
#   * uBlock/Bitwarden/DarkReader/etc.  -> ExtensionSettings force-install
#
# NOTE: Chromium has no userChrome.css / userContent.css equivalent. The palette
# is applied to the browser *chrome* through a generated theme extension (loaded
# with --load-extension, so colours bypass Material You) and to the custom
# startpage through colours.css (which shares the Firefox --fx-* variables).
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

      # Where the startpage is materialised. The hand-written page files are
      # live symlinks into the checkout (nixos.liveLinks) and colours.css is a
      # generated Hjem file, so both land in the same directory.
      startpageDir = "/home/${config.username}/.config/helium/startpage";
      startpageUrl = "file://${startpageDir}/index.html";

      # Browser theme extension
      # Chromium has no userChrome.css equivalent. The BrowserThemeColor policy
      # takes a seed but runs it through Material You, so the chrome comes out as
      # a derived tonal palette rather than the requested colours. A classic
      # theme extension applies its colours literally, so generate one from the
      # active palette and load it with --load-extension.
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

      # Perceived luminance, used only to pick a light/dark color_scheme.
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

      # Chromium expects a single comma-separated --enable/--disable-features flag.
      enabledFeatures = [
        "TouchpadOverscrollHistoryNavigation"
        # Hardware video decoding/encoding (VA-API, incl. NVIDIA through
        # nvidia-vaapi-driver). Named for the Chromium version Helium ships.
        "VaapiVideoDecoder"
        "VaapiVideoEncodeAccelerator"
        "OverlayScrollbar"
      ];

      disabledFeatures = [
        # PeskyFox: remove shipping clutter / integrations we never use
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

      # Command-line flags
      # Mirrors the Firefox FastFox/privacy/graphics/theme preference groups.
      # --ozone-platform-hint=auto is injected by the upstream package wrapper
      # when NIXOS_OZONE_WL + WAYLAND_DISPLAY are set, so it is not repeated.
      defaultFlags = [
        # Wayland / Ozone
        "--enable-features=${lib.concatStringsSep "," enabledFeatures}"
        "--disable-features=${lib.concatStringsSep "," disabledFeatures}"

        # GPU / hardware acceleration
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-accelerated-video-decode"

        # Cosmetic animations off (mirrors toolkit.cosmeticAnimations.enabled=false)
        "--force-prefers-reduced-motion"

        # Network / privacy: speculative loading & preconnect off
        "--dns-prefetch-disable"
        "--disable-preconnect"
        "--no-pings"
        "--no-default-browser-check"

        # Disk avoidance: cap the on-disk cache (keeps RAM footprint low)
        "--disk-cache-size=52428800"
      ];

      # Helium only accepts a local (file://) new-tab page through the
      # ungoogled-chromium `--custom-ntp` switch; the NewTabPageLocation policy
      # silently drops non-http(s) URLs.
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

      # Startpage theming
      # The browser chrome gets the palette via the theme extension above; this
      # file only styles the local startpage (same --fx-* variables as Firefox).
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

      # Extensions
      # Chrome Web Store IDs. Helium is Chromium-based and queries the CWS
      # update endpoint for force-installed extensions.
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

      # Enterprise policies
      # Mirrors the Firefox preference groups. Unknown keys are ignored by
      # Chromium; users can override anything via `policies`/`extraPolicies`.
      # The new-tab page itself is set with --custom-ntp (see startpageFlags);
      # here we only wire the home button to that same page.
      startupPolicies = lib.optionalAttrs cfg.enableCustomStartpage {
        HomepageIsNewTabPage = true;
        ShowHomeButton = true;
      };

      defaultPolicies = {
        # Startup
        RestoreOnStartup = 1; # 1 = restore the last session
        DefaultBrowserSettingEnabled = false;

        # Default search provider (DuckDuckGo)
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        DefaultSearchProviderKeyword = "ddg";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";
        DefaultSearchProviderEncodings = [ "UTF-8" ];
        SearchSuggestEnabled = false;

        # Telemetry, reporting, experiments & feedback
        MetricsReportingEnabled = false;
        ChromeVariations = 2; # 2 = disable all variations/experiments
        UserFeedbackAllowed = false;
        CloudReportingEnabled = false;
        SafeBrowsingExtendedReportingEnabled = false;
        UrlKeyedAnonymizedDataCollectionEnabled = false;
        PromotionalTabsEnabled = false;
        BackgroundModeEnabled = false;
        BrowserSignin = 0; # disable browser sign-in
        SyncDisabled = true;
        # Keep local Safe Browsing, drop the remote download verdict lookups
        SafeBrowsingProtectionLevel = 1;
        HideWebStoreIcon = true;

        # Network & privacy
        NetworkPredictionOptions = 2; # 2 = never (DNS prefetch / preconnect)
        DnsOverHttpsMode = "off";
        BuiltInDnsClientEnabled = false;
        DNSInterceptionChecksEnabled = false;
        BlockThirdPartyCookies = true;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;
        PrivacySandboxAdMeasurementEnabled = false;
        PrivacySandboxPromptEnabled = false;
        PrivacySandboxRelatedWebsiteSetsEnabled = false;

        # Passwords & autofill (Bitwarden handles this)
        PasswordManagerEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;

        # Permissions: default deny (mirrors permissions.default.*)
        DefaultNotificationsSetting = 2; # 2 = block
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

        # Security
        HttpsOnlyMode = "force_enabled";
        PromptForDownloadLocation = true;
        DeveloperToolsAvailability = 0; # 0 = allow DevTools
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

        # Themed startpage. The hand-written page files are live symlinks into
        # the checkout (same pattern as quickshell) while colours.css is a
        # generated Hjem file in the same directory; `contents` mode leaves the
        # Hjem symlink alone, so activation never writes into the checkout.
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
