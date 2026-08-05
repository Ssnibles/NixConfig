{
  self,
  inputs,
  config,
  ...
}:
{
  flake.nixosModules.zen-browser =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.firefox = {
        enable = true;
        package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
        policies = {
          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = true;
          };
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          Preferences = {
            "webgl.disabled" = false;
            "privacy.resistFingerprinting" = false;
            "privacy.clearOnShutdown.history" = false;
            "privacy.clearOnShutdown.cookies" = false;
            "network.cookie.lifetimePolicy" = 0;
            "cookiebanners.service.mode.privateBrowsing" = 2;
            "cookiebanners.service.mode" = 2;
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "browser.startup.homepage" = "https://startpage.com";
            "browser.tabs.unloadOnLowMemory" = true;
            "zen.view.compact.show-sidebar-and-toolbar-on-hover" = true;
            "browser.sessionstore.interval" = 600000;
            "zen.theme.content-element-separation" = 0;
            "zen.theme.border-radius" = 0;
            "widget.gtk.rounded-bottom-corners.enabled" = false;
          };
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
              installation_mode = "force_installed";
            };
          };
        };
      };
    };
}
