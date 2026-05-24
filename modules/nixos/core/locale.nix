{ ... }:

{
  time.timeZone = "Pacific/Auckland";

  i18n = {
    defaultLocale = "en_NZ.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_NZ.UTF-8";
      LC_MEASUREMENT = "en_NZ.UTF-8";
    };
  };
}
