{ lib, ... }:
{
  flake.nixosModules.theme-palette = { config, lib, ... }: let
    schemes = {
      catppuccin-mocha = {
        bg = "1e1e2e";
        fg = "cdd6f4";
        accent = "cba6f7";
        red = "f38ba8";
      };

      gruvbox-dark = {
        bg = "282828";
        fg = "ebdbb2";
        accent = "fe8019";
        red = "fb4934";
      };

      default-dark = {
        bg = "181818";
        fg = "d8d8d8";
        accent = "7cafc2";
        red = "ab4642";
      };

      default-light = {
        bg = "f8f8f8";
        fg = "383838";
        accent = "7cafc2";
        red = "ab4642";
      };

      gruvbox-dark-hard = {
        bg = "1d2021";
        fg = "d5c4a1";
        accent = "83a598";
        red = "fb4934";
      };

      gruvbox-light-hard = {
        bg = "f9f5d7";
        fg = "504945";
        accent = "076678";
        red = "9d0006";
      };

      rose-pine = {
        bg = "191724";
        fg = "e0def4";
        accent = "c4a7e7";
        red = "eb6f92";
      };

      rose-pine-moon = {
        bg = "232136";
        fg = "e0def4";
        accent = "c4a7e7";
        red = "eb6f92";
      };

      rose-pine-dawn = {
        bg = "faf4ed";
        fg = "575279";
        accent = "907aa9";
        red = "b4637a";
      };

      everforest-light = {
        bg = "fdf6e3";
        fg = "5c6a72";
        accent = "3a94c5";
        red = "f85552";
      };

      vague = {
        bg = "141415";
        fg = "cdcdcd";
        accent = "6e94b2";
        red = "d8647e";
      };
    };
  in {
    config.theme.colors = schemes.${config.theme.active};
  };
}
