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

      zen-package = pkgs.wrapFirefox inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped {
        pname = "zen-browser";

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
          };
        };
      };
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
