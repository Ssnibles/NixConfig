{
  # Default wallpaper used by any theme that doesn't specify its own.
  wallpaper = ../../wallpapers/celestial-lighter.png;

  # Theme key => base16 scheme metadata used by modules/home/stylix.nix
  themes = {
    "catppuccin-mocha" = {
      scheme = "catppuccin-mocha.yaml";
      polarity = "dark";
    };

    "default-dark" = {
      scheme = "default-dark.yaml";
      polarity = "dark";
    };

    "default-light" = {
      scheme = "default-light.yaml";
      polarity = "light";
    };

    "gruvbox-dark-hard" = {
      scheme = "gruvbox-dark-hard.yaml";
      polarity = "dark";
    };

    "gruvbox-light-hard" = {
      scheme = "gruvbox-light-hard.yaml";
      polarity = "light";
    };

    "rose-pine" = {
      scheme = "rose-pine.yaml";
      polarity = "dark";
    };

    "rose-pine-moon" = {
      scheme = "rose-pine-moon.yaml";
      polarity = "dark";
    };

    "rose-pine-dawn" = {
      scheme = "rose-pine-dawn.yaml";
      polarity = "light";
    };

    "everforest-light" = {
      polarity = "light";
      scheme = {
        scheme = "Everforest Light (Medium)";
        author = "Marcio Sobel (https://github.com/marciosobel)";
        variant = "light";
        base00 = "fdf6e3";
        base01 = "f4f0d9";
        base02 = "e6e2cc";
        base03 = "939f91";
        base04 = "829181";
        base05 = "5c6a72";
        base06 = "475258";
        base07 = "2d353b";
        base08 = "f85552";
        base09 = "f57d26";
        base0A = "dfa000";
        base0B = "8da101";
        base0C = "35a77c";
        base0D = "3a94c5";
        base0E = "df69ba";
        base0F = "829181";
      };
    };

    "vague" = {
      polarity = "dark";
      scheme = {
        scheme = "Vague";
        author = "Josh";
        variant = "dark";
        base00 = "141415";
        base01 = "1c1c24";
        base02 = "252530";
        base03 = "606079";
        base04 = "878787";
        base05 = "cdcdcd";
        base06 = "d8d8d8";
        base07 = "e6e6e6";
        base08 = "d8647e";
        base09 = "e8b589";
        base0A = "f3be7c";
        base0B = "7fa563";
        base0C = "b4d4cf";
        base0D = "6e94b2";
        base0E = "bb9dbd";
        base0F = "c48282";
      };
    };
  };
}
