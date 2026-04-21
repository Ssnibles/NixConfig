let
  wallpaper = ../../wallpapers/kalen-emsley-Bkci_8qcdvQ-unsplash.jpg;
in
{
  # Theme key => base16 scheme metadata used by modules/home/stylix.nix
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

  # Example custom inline Base16 theme.
  # Copy this block, rename the key, and adjust base00-base0F.
  "example-custom-ocean" = {
    polarity = "dark";
    scheme = {
      scheme = "Example Custom Ocean";
      author = "You";
      base00 = "0b0f14";
      base01 = "111822";
      base02 = "1a2431";
      base03 = "5b6b81";
      base04 = "7d8fa6";
      base05 = "c7d2e0";
      base06 = "dbe5f2";
      base07 = "f2f7ff";
      base08 = "ff7b72";
      base09 = "ffb86b";
      base0A = "ffd866";
      base0B = "7ee787";
      base0C = "79c0ff";
      base0D = "58a6ff";
      base0E = "d2a8ff";
      base0F = "ffa198";
    };
  };

  "vague" = {
    polarity = "dark";
    scheme = {
      scheme = "Vague";
      author = "Josh";
      base00 = "141415";
      base01 = "1c1c24";
      base02 = "252530";
      base03 = "606079";
      base04 = "878787";
      base05 = "cdcdcd";
      base06 = "9bb4bc";
      base07 = "b4d4cf";
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
}
