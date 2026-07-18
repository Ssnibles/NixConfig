{
  self,
  inputs,
  hjem,
  config,
  ...
}:
{
  flake.nixosModules.librewolf =
    { pkgs, lib, ... }:
    {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;
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
            "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing
            "cookiebanners.service.mode" = 2; # Block cookie banners
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
          };
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
          };
        };
      };

      hjem.users."${config.username}" = {
        xdg.mime-apps.default-applications = {
          "text/html" = [
            "librewolf.desktop"
          ];
          "x-scheme-handler/http" = [
            "librewolf.desktop"
          ];
          "x-scheme-handler/https" = [
            "librewolf.desktop"
          ];
          "x-scheme-handler/about" = [
            "librewolf.desktop"
          ];
          "x-scheme-handler/unknown" = [
            "librewolf.desktop"
          ];
        };
      };

      environment.etc."firefox/policies/policies.json".target = "librewolf/policies/policies.json";
    };
}
