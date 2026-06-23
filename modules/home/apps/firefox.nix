{
  pkgs,
  inputs,
  ...
}:
{
  programs.firefox = {
    enable = true;
    package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    configPath = ".zen";
    profiles.josh = {
      isDefault = true;
      preConfig = builtins.readFile "${inputs.betterfox}/user.js";
      extensions = {
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
        ];
      };
      extensions.force = true;
      settings = {
        "browser.startup.homepage" = "https://startpage.com";
        "browser.tabs.unloadOnLowMemory" = true;
        "zen.view.compact.show-sidebar-and-toolbar-on-hover" = true;
        "browser.sessionstore.interval" = 600000;
      };
      extraConfig = ''
        user_pref("zen.theme.content-element-separation", 0);
        user_pref("zen.theme.border-radius", 0);
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
      '';
    };
  };
}
