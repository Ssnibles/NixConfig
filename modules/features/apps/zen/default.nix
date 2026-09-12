# =============================================================================
# Zen Browser Feature
# =============================================================================
# Zen Browser installation, Firefox enterprise policy restrictions, and default
# xdg-open MIME associations with dynamic system theme integration.
# =============================================================================
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
      cfg = config.features.zen-browser;

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

      colorsCss = ''
        /* ==========================================================================
           Zen Browser Dynamic Theme Palette (Generated from config.theme.colors)
           Active Scheme: ${config.theme.active}
           ========================================================================== */
        :root {
          /* System Palette Tokens */
          --theme-bg: #${bg};
          --theme-bg-raised: #${bgRaised};
          --theme-bg-subtle: #${bgSubtle};
          --theme-border: #${border};
          --theme-fg: #${fg};
          --theme-fg-mid: #${fgMid};
          --theme-fg-dim: #${fgDim};
          --theme-accent: #${accent};
          --theme-teal: #${teal};
          --theme-purple: #${purple};
          --theme-green: #${green};
          --theme-yellow: #${yellow};
          --theme-red: #${red};
          --theme-orange: #${orange};

          /* System Typography (Quickshell & System Theme) */
          --theme-font-sans: "${config.theme.fonts.sans}", system-ui, -apple-system, sans-serif;
          --theme-font-mono: "${config.theme.fonts.monospace}", monospace;
          --theme-font-serif: "${config.theme.fonts.serif}", Georgia, serif;

          /* UI Metrics (Refined Quickshell Design System) */
          --theme-radius-sm: 6px;
          --theme-radius: 8px;
          --theme-radius-lg: 12px;
          --theme-radius-pill: 9999px;
          --theme-transition-fast: 0.12s cubic-bezier(0.4, 0, 0.2, 1);
          --theme-transition: 0.2s cubic-bezier(0.4, 0, 0.2, 1);
          --theme-transition-slow: 0.35s cubic-bezier(0.4, 0, 0.2, 1);
          --theme-shadow-card: 0 4px 16px rgba(0, 0, 0, 0.25);
          --theme-shadow-popup: 0 10px 30px rgba(0, 0, 0, 0.4);

          /* Zen Browser Native Design Tokens */
          --zen-primary-color: #${accent} !important;
          --zen-colors-primary: #${bgSubtle} !important;
          --zen-colors-secondary: #${bgSubtle} !important;
          --zen-colors-tertiary: #${bg} !important;
          --zen-colors-border: #${border} !important;
          --zen-main-browser-background: #${bg} !important;
          --zen-themed-toolbar-bg: #${bg} !important;
          --toolbox-bgcolor-inactive: #${bg} !important;
          --toolbar-bgcolor: #${bg} !important;
          --toolbar-color: #${fg} !important;
          --toolbar-field-color: #${fg} !important;
          --toolbar-field-focus-color: #${fg} !important;
          --toolbarbutton-icon-fill: #${accent} !important;
          --tab-selected-textcolor: #${accent} !important;
          --lwt-text-color: #${fg} !important;
          --lwt-sidebar-text-color: #${fg} !important;
          --lwt-sidebar-background-color: #${bg} !important;
          --sidebar-text-color: #${fg} !important;
          --arrowpanel-background: color-mix(in srgb, #${bgRaised} 90%, transparent) !important;
          --arrowpanel-color: #${fg} !important;
          --arrowpanel-border-color: #${border} !important;
          --panel-background: color-mix(in srgb, #${bgRaised} 90%, transparent) !important;
          --panel-color: #${fg} !important;
          --panel-border-color: #${border} !important;
          --newtab-background-color: #${bg} !important;
          --newtab-text-primary-color: #${fg} !important;
          --urlbar-box-bgcolor: #${bgRaised} !important;
          --urlbar-box-focus-bgcolor: #${bgRaised} !important;
          --urlbar-box-hover-bgcolor: #${bgRaised} !important;

          /* In-Content Page Tokens */
          --in-content-page-background: #${bg} !important;
          --in-content-page-color: #${fg} !important;
          --in-content-box-background: #${bgRaised} !important;
          --in-content-box-border-color: #${border} !important;
          --color-accent-primary: #${accent} !important;
          --color-accent-primary-hover: color-mix(in srgb, #${accent} 85%, white) !important;
          --color-accent-primary-active: color-mix(in srgb, #${accent} 70%, white) !important;
        }

        /* Container Tab Accent Colors */
        .identity-color-blue {
          --identity-tab-color: #${accent} !important;
          --identity-icon-color: #${accent} !important;
        }
        .identity-color-turquoise {
          --identity-tab-color: #${teal} !important;
          --identity-icon-color: #${teal} !important;
        }
        .identity-color-green {
          --identity-tab-color: #${green} !important;
          --identity-icon-color: #${green} !important;
        }
        .identity-color-yellow {
          --identity-tab-color: #${yellow} !important;
          --identity-icon-color: #${yellow} !important;
        }
        .identity-color-orange {
          --identity-tab-color: #${orange} !important;
          --identity-icon-color: #${orange} !important;
        }
        .identity-color-red {
          --identity-tab-color: #${red} !important;
          --identity-icon-color: #${red} !important;
        }
        .identity-color-pink {
          --identity-tab-color: #${purple} !important;
          --identity-icon-color: #${purple} !important;
        }
        .identity-color-purple {
          --identity-tab-color: #${accent} !important;
          --identity-icon-color: #${accent} !important;
        }
      '';

      extraPolicies = {
        # Top-level Enterprise Policies
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableFirefoxAccounts = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;

        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };

        # Extensions: installed automatically from AMO
        ExtensionSettings = {
          # uBlock Origin
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          };
        };

        # about:config Preferences
        Preferences = {
          "browser.tabs.inTitlebar" = {
            Value = 0;
            Status = "locked";
          };
          "privacy.donottrackheader.enabled" = {
            Value = true;
            Status = "locked";
          };
          "toolkit.legacyUserProfileCustomizations.stylesheets" = {
            Value = true;
            Status = "locked";
          };
          "layout.css.backdrop-filter.enabled" = {
            Value = true;
            Status = "locked";
          };
          "gfx.webrender.all" = {
            Value = true;
            Status = "locked";
          };
          "media.ffmpeg.vaapi.enabled" = {
            Value = true;
            Status = "locked";
          };
          "svg.context-properties.content.enabled" = {
            Value = true;
            Status = "locked";
          };
          "browser.compactmode.show" = {
            Value = true;
            Status = "locked";
          };
          "zen.theme.acrylic-elements" = {
            Value = true;
            Status = "locked";
          };
          # Required for Zen window & popup transparency on Linux
          "zen.widget.linux.transparency" = {
            Value = true;
            Status = "locked";
          };
          "widget.transparent-windows" = {
            Value = true;
            Status = "locked";
          };
          "browser.tabs.allow_transparent_browser" = {
            Value = true;
            Status = "locked";
          };
        };
      };

      zen-unwrapped =
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight-unwrapped.override
          {
            inherit extraPolicies;
          };

      zen-package = pkgs.wrapFirefox (zen-unwrapped // {
        version = zen-unwrapped.firefoxVersion or "9999";
      }) {
        version = zen-unwrapped.version;
        inherit extraPolicies;
      };
    in
    {
      options.features.zen-browser = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Zen Browser module.";
        };

        enableCustomCss = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable custom userChrome styling and dynamic theme integration.";
        };

        enableUserChrome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Alias for enableCustomCss.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          zen-package
          (pkgs.writeShellScriptBin "zen" ''exec zen-twilight "$@"'')
          (pkgs.writeShellScriptBin "zen-browser" ''exec zen-twilight "$@"'')
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mimeapps.list" = {
              text = ''
                [Default Applications]
                text/html=zen-twilight.desktop;zen.desktop
                x-scheme-handler/http=zen-twilight.desktop;zen.desktop
                x-scheme-handler/https=zen-twilight.desktop;zen.desktop
                x-scheme-handler/about=zen-twilight.desktop;zen.desktop
                x-scheme-handler/unknown=zen-twilight.desktop;zen.desktop
              '';
            };
          };
        };

        # Direct repository symlinks for live-reloading UI customization (userChrome & userContent)
        # Bypasses Nix store so edits in NixConfig take effect immediately on Zen Browser restart
        system.activationScripts.zen-browser-config = ''
          ZEN_DIR="/home/${config.username}/.config/zen"
          REPO_ZEN_DIR="/home/${config.username}/NixConfig/modules/features/apps/zen"

          # Write dynamic theme colors to repository for local editing & live-reload
          if [ -d "$REPO_ZEN_DIR" ]; then
            cat << 'EOF' > "$REPO_ZEN_DIR/colors.css"
${colorsCss}
EOF
            chown ${config.username}:users "$REPO_ZEN_DIR/colors.css"
          fi

          if [ -d "$ZEN_DIR" ]; then
            for PROFILE in "$ZEN_DIR"/*/; do
              if [ -d "$PROFILE" ] && [ -f "$PROFILE/compatibility.ini" -o -f "$PROFILE/prefs.js" -o -f "$PROFILE/zen-keyboard-shortcuts.json" ]; then
                ${lib.optionalString (cfg.enableCustomCss || cfg.enableUserChrome) ''
                  CHROME_DIR="$PROFILE/chrome"
                  mkdir -p "$CHROME_DIR"

                  # Deploy dynamic colors.css to the profile
                  cat << 'EOF' > "$CHROME_DIR/colors.css"
${colorsCss}
EOF
                  chown ${config.username}:users "$CHROME_DIR/colors.css"

                  # Symlink userChrome and userContent CSS directly to repo for instant live reload
                  if [ -d "$REPO_ZEN_DIR" ]; then
                    ln -sfn "$REPO_ZEN_DIR/userChrome.css" "$CHROME_DIR/userChrome.css"
                    ln -sfn "$REPO_ZEN_DIR/userContent.css" "$CHROME_DIR/userContent.css"
                  else
                    cp -f ${./userChrome.css} "$CHROME_DIR/userChrome.css"
                    cp -f ${./userContent.css} "$CHROME_DIR/userContent.css"
                  fi

                  chown -h ${config.username}:users "$CHROME_DIR/userChrome.css" "$CHROME_DIR/userContent.css"
                  chown -R ${config.username}:users "$CHROME_DIR"
                ''}

                # Enforce declarative keyboard shortcuts:
                # Toggle Compact Mode:   Ctrl+Alt+E
                # Toggle Floating Sidebar: Ctrl+E
                SHORTCUTS_FILE="$PROFILE/zen-keyboard-shortcuts.json"
                if [ -f "$SHORTCUTS_FILE" ]; then
                  ${pkgs.jq}/bin/jq '
                    .shortcuts |= map(
                      if .id == "zen-compact-mode-toggle" then
                        .key = "E" | .modifiers = { control: true, alt: true, shift: false, meta: false, accel: true }
                      elif .id == "zen-compact-mode-show-sidebar" then
                        .key = "E" | .modifiers = { control: true, alt: false, shift: false, meta: false, accel: true }
                      else . end
                    )
                  ' "$SHORTCUTS_FILE" > "$SHORTCUTS_FILE.tmp" && mv "$SHORTCUTS_FILE.tmp" "$SHORTCUTS_FILE"
                  chown ${config.username}:users "$SHORTCUTS_FILE"
                fi
              fi
            done
          fi
        '';
      };
    };
}
