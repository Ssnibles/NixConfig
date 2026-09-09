# =============================================================================
# Zen Browser Feature
# =============================================================================
# Zen Browser installation, Firefox enterprise policy restrictions, and default
# xdg-open MIME associations.
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
        };
      };

      sources = builtins.fromJSON (builtins.readFile "${inputs.zen-browser}/sources.json");
      catppuccinZen = pkgs.fetchFromGitHub {
        inherit (sources.addons.catppuccin) rev hash;
        repo = "zen-browser";
        owner = "catppuccin";
      };

      userChromeCss = ''
        /* ==========================================================================
           Zen Browser Custom userChrome.css
           Official Catppuccin theme preset + polished floating sidebar & compact mode
           ========================================================================== */
        @import "catppuccin/userChrome.css";

        /* Seamless floating sidebar styling */
        #zen-sidebar-web-panel {
          border-radius: 12px !important;
          box-shadow: 0 6px 24px rgba(0, 0, 0, 0.35) !important;
          border: 1px solid var(--zen-colors-border, rgba(255, 255, 255, 0.1)) !important;
          transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.2s ease !important;
        }

        /* Floating compact toolbar & URL bar */
        #zen-compact-mode-toolbar-wrapper {
          border-radius: 10px !important;
          backdrop-filter: blur(12px) !important;
          transition: all 0.2s ease-in-out !important;
        }

        .urlbar-background {
          border-radius: 10px !important;
          border: 1px solid var(--zen-colors-border, rgba(255, 255, 255, 0.08)) !important;
          transition: border-color 0.15s ease, box-shadow 0.15s ease !important;
        }

        #urlbar[focused="true"] .urlbar-background {
          border-color: var(--zen-primary-color, #cba6f7) !important;
          box-shadow: 0 0 0 2px rgba(203, 166, 247, 0.2) !important;
        }

        /* Workspace & Tab buttons polish */
        #zen-workspaces-button {
          border-radius: 8px !important;
          transition: background-color 0.15s ease !important;
        }

        .tabbrowser-tab {
          border-radius: 8px !important;
          margin: 2px 4px !important;
          transition: background-color 0.12s ease !important;
        }

        /* Hide redundant scrollbars on vertical tab containers */
        #tabbrowser-tabs,
        #zen-sidebar-top-buttons,
        #zen-sidebar-bottom-buttons {
          scrollbar-width: none !important;
        }

        /* Smooth floating sidebar transition */
        #zen-appcontent-wrapper {
          transition: margin 0.25s cubic-bezier(0.4, 0, 0.2, 1) !important;
        }
      '';

      userContentCss = ''
        /* ==========================================================================
           Zen Browser Custom userContent.css
           ========================================================================== */
        @import "catppuccin/userContent.css";
      '';

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

        enableUserChrome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable custom userChrome styling and official Catppuccin theme preset.";
        };

        catppuccinFlavor = lib.mkOption {
          type = lib.types.str;
          default = "Mocha";
          description = "Catppuccin theme flavor (Mocha, Macchiato, Frappe, Latte).";
        };

        catppuccinAccent = lib.mkOption {
          type = lib.types.str;
          default = "Mauve";
          description = "Catppuccin theme accent (Mauve, Blue, Peach, Lavender, etc.).";
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

        system.activationScripts.zen-browser-config = ''
          ZEN_DIR="/home/${config.username}/.config/zen"
          if [ -d "$ZEN_DIR" ]; then
            for PROFILE in "$ZEN_DIR"/*/; do
              if [ -d "$PROFILE" ] && [ -f "$PROFILE/compatibility.ini" -o -f "$PROFILE/prefs.js" -o -f "$PROFILE/zen-keyboard-shortcuts.json" ]; then
                ${lib.optionalString cfg.enableUserChrome ''
                  CHROME_DIR="$PROFILE/chrome"
                  mkdir -p "$CHROME_DIR"

                  # Link official Catppuccin theme preset from zen-browser-flake
                  ln -sfn "${catppuccinZen}/themes/${cfg.catppuccinFlavor}/${cfg.catppuccinAccent}" "$CHROME_DIR/catppuccin"

                  # Deploy userChrome and userContent CSS
                  cat << 'EOF' > "$CHROME_DIR/userChrome.css"
          ${userChromeCss}
          EOF

                  cat << 'EOF' > "$CHROME_DIR/userContent.css"
          ${userContentCss}
          EOF
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
