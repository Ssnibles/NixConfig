{ ... }:
{
  nixos.modules.shared = { config, lib, ... }: let
    schemes = {
      catppuccin-mocha = {
        bg        = "1e1e2e";
        bgRaised  = "181825";
        bgSubtle  = "313244";
        border    = "313244";
        fg        = "cdd6f4";
        fgMid     = "585b70";
        fgDim     = "45475a";
        accent    = "cba6f7";
        teal      = "94e2d5";
        purple    = "f5c2e7";
        green     = "a6e3a1";
        yellow    = "f9e2af";
        red       = "f38ba8";
        orange    = "fab387";
      };

      gruvbox-dark = {
        bg        = "282828";
        bgRaised  = "3c3836";
        bgSubtle  = "504945";
        border    = "504945";
        fg        = "ebdbb2";
        fgMid     = "a89984";
        fgDim     = "665c54";
        accent    = "fe8019";
        teal      = "8ec07c";
        purple    = "d3869b";
        green     = "b8bb26";
        yellow    = "fabd2f";
        red       = "fb4934";
        orange    = "fe8019";
      };

      default-dark = {
        bg        = "181818";
        bgRaised  = "282828";
        bgSubtle  = "383838";
        border    = "383838";
        fg        = "d8d8d8";
        fgMid     = "a0a0a0";
        fgDim     = "585858";
        accent    = "7cafc2";
        teal      = "86c1b9";
        purple    = "ba8baf";
        green     = "a1b56c";
        yellow    = "f7ca88";
        red       = "ab4642";
        orange    = "dc9656";
      };

      default-light = {
        bg        = "f8f8f8";
        bgRaised  = "e8e8e8";
        bgSubtle  = "dfdfdf";
        border    = "dfdfdf";
        fg        = "383838";
        fgMid     = "585858";
        fgDim     = "b8b8b8";
        accent    = "7cafc2";
        teal      = "86c1b9";
        purple    = "ba8baf";
        green     = "a1b56c";
        yellow    = "f7ca88";
        red       = "ab4642";
        orange    = "dc9656";
      };

      gruvbox-dark-hard = {
        bg        = "1d2021";
        bgRaised  = "2d3132";
        bgSubtle  = "3d4345";
        border    = "3d4345";
        fg        = "d5c4a1";
        fgMid     = "a89984";
        fgDim     = "665c54";
        accent    = "83a598";
        teal      = "8ec07c";
        purple    = "d3869b";
        green     = "b8bb26";
        yellow    = "fabd2f";
        red       = "fb4934";
        orange    = "fe8019";
      };

      gruvbox-light-hard = {
        bg        = "f9f5d7";
        bgRaised  = "eee8d0";
        bgSubtle  = "e2dcc5";
        border    = "e2dcc5";
        fg        = "504945";
        fgMid     = "8a7d6e";
        fgDim     = "9b8c7a";
        accent    = "076678";
        teal      = "689d6a";
        purple    = "8f3f71";
        green     = "79740e";
        yellow    = "b57614";
        red       = "9d0006";
        orange    = "af3a03";
      };

      rose-pine = {
        bg        = "191724";
        bgRaised  = "1f1d2e";
        bgSubtle  = "26233a";
        border    = "26233a";
        fg        = "e0def4";
        fgMid     = "908caa";
        fgDim     = "6e6a86";
        accent    = "c4a7e7";
        teal      = "9ccfd8";
        purple    = "31748f";
        green     = "3e8fb0";
        yellow    = "f6c177";
        red       = "eb6f92";
        orange    = "ebbcba";
      };

      rose-pine-moon = {
        bg        = "232136";
        bgRaised  = "2a273f";
        bgSubtle  = "312f44";
        border    = "312f44";
        fg        = "e0def4";
        fgMid     = "908caa";
        fgDim     = "6e6a86";
        accent    = "c4a7e7";
        teal      = "9ccfd8";
        purple    = "31748f";
        green     = "3e8fb0";
        yellow    = "f6c177";
        red       = "eb6f92";
        orange    = "ebbcba";
      };

      rose-pine-dawn = {
        bg        = "faf4ed";
        bgRaised  = "fffaf3";
        bgSubtle  = "f2e9de";
        border    = "f2e9de";
        fg        = "575279";
        fgMid     = "9893a5";
        fgDim     = "797593";
        accent    = "907aa9";
        teal      = "d7827e";
        purple    = "907aa9";
        green     = "286983";
        yellow    = "ea9d34";
        red       = "b4637a";
        orange    = "ea9d34";
      };

      everforest-light = {
        bg        = "fdf6e3";
        bgRaised  = "f4f0d9";
        bgSubtle  = "e6e2cc";
        border    = "e6e2cc";
        fg        = "5c6a72";
        fgMid     = "829181";
        fgDim     = "939f91";
        accent    = "3a94c5";
        teal      = "35a77c";
        purple    = "df69ba";
        green     = "8da101";
        yellow    = "dfa000";
        red       = "f85552";
        orange    = "f57d26";
      };

      vague = {
        bg        = "141415";
        bgRaised  = "1c1c24";
        bgSubtle  = "252530";
        border    = "252530";
        fg        = "cdcdcd";
        fgMid     = "878787";
        fgDim     = "606079";
        accent    = "6e94b2";
        teal      = "b4d4cf";
        purple    = "bb9dbd";
        green     = "7fa563";
        yellow    = "f3be7c";
        red       = "d8647e";
        orange    = "e8b589";
      };
    };
  in {
    config.theme.colors = schemes.${config.theme.active};
  };
}
