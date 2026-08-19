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

      zen-package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        buildCommand =
          oldAttrs.buildCommand
          + ''
            policyFile="$out/lib/zen/distribution/policies.json"
            mkdir -p "$(dirname "$policyFile")"

            cat <<'EOF' > "$policyFile"
            {
              "policies": {
                "AutofillAddressEnabled": false,
                "AutofillCreditCardEnabled": false,
                "DisableFirefoxAccounts": true,
                "DisableFirefoxStudies": true,
                "DisablePocket": true,
                "DisableTelemetry": true,
                "EnableTrackingProtection": {
                  "Value": true,
                  "Cryptomining": true,
                  "Fingerprinting": true,
                  "EmailTracking": true
                },
                "OfferToSaveLogins": false,
                "PasswordManagerEnabled": false,
                "Preferences": {
                  "browser.tabs.inTitlebar": 0,
                  "privacy.donottrackheader.enabled": true
                }
              }
            }
            EOF
          '';
      });
    in
    {
      options.features.zen-browser.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Zen Browser module.";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ zen-package ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mimeapps.list" = {
              text = ''
                [Default Applications]
                text/html=zen.desktop
                x-scheme-handler/http=zen.desktop
                x-scheme-handler/https=zen.desktop
                x-scheme-handler/about=zen.desktop
                x-scheme-handler/unknown=zen.desktop
              '';
            };
          };
        };
      };
    };
}
